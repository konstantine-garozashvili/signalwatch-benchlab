#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REST_DIR="${ROOT_DIR}/benchmark/results/rest"
GRPC_DIR="${ROOT_DIR}/benchmark/results/grpc"
OUTPUT_PATH="${ROOT_DIR}/benchmark/results/report-latest.md"
HTML_OUTPUT_PATH="${ROOT_DIR}/benchmark/results/report-latest.html"

find_latest_timestamp() {
  local dir="$1"
  local latest=""

  if [[ ! -d "${dir}" ]]; then
    return 0
  fi

  while IFS= read -r file_path; do
    file_name="$(basename "${file_path}")"
    timestamp="${file_name%%-scenario-*}"
    if [[ "${timestamp}" != "${file_name}" ]]; then
      if [[ -z "${latest}" || "${timestamp}" > "${latest}" ]]; then
        latest="${timestamp}"
      fi
    fi
  done < <(ls -1 "${dir}"/*.json 2>/dev/null || true)

  printf '%s' "${latest}"
}

REST_TIMESTAMP="$(find_latest_timestamp "${REST_DIR}")"
GRPC_TIMESTAMP="$(find_latest_timestamp "${GRPC_DIR}")"
LATEST_TIMESTAMP=""

if [[ -n "${REST_TIMESTAMP}" && -n "${GRPC_TIMESTAMP}" ]]; then
  if [[ "${REST_TIMESTAMP}" > "${GRPC_TIMESTAMP}" ]]; then
    LATEST_TIMESTAMP="${REST_TIMESTAMP}"
  else
    LATEST_TIMESTAMP="${GRPC_TIMESTAMP}"
  fi
elif [[ -n "${REST_TIMESTAMP}" ]]; then
  LATEST_TIMESTAMP="${REST_TIMESTAMP}"
elif [[ -n "${GRPC_TIMESTAMP}" ]]; then
  LATEST_TIMESTAMP="${GRPC_TIMESTAMP}"
fi

if [[ -z "${LATEST_TIMESTAMP}" ]]; then
  echo "Aucun resultat de benchmark detecte dans benchmark/results." >&2
  echo "Lancez d'abord: make bench" >&2
  exit 1
fi

python3 - "${ROOT_DIR}" "${LATEST_TIMESTAMP}" "${OUTPUT_PATH}" "${HTML_OUTPUT_PATH}" <<'PY'
import glob
import html
import json
import os
import sys
from datetime import datetime

root_dir, ts, output_path, html_output_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

rest_dir = os.path.join(root_dir, "benchmark", "results", "rest")
grpc_dir = os.path.join(root_dir, "benchmark", "results", "grpc")


def fmt_num(value):
    if value is None:
        return "n/a"
    try:
        return f"{float(value):.2f}"
    except (TypeError, ValueError):
        return "n/a"


def fmt_pct(value):
    if value is None:
        return "n/a"
    try:
        return f"{float(value) * 100:.2f}%"
    except (TypeError, ValueError):
        return "n/a"


def parse_rest(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None

    metrics = data.get("metrics", {})
    duration = metrics.get("http_req_duration", {})
    reqs = metrics.get("http_reqs", {})
    failed = metrics.get("http_req_failed", {})

    return {
        "lat_p50": duration.get("med"),
        "lat_p95": duration.get("p(95)"),
        "lat_p99": duration.get("p(99)"),
        "rps": reqs.get("rate"),
        "err": failed.get("value"),
    }


def grpc_latency_ms(lat_dist, percentile):
    if isinstance(lat_dist, dict):
        return lat_dist.get(str(percentile), lat_dist.get(percentile))
    if isinstance(lat_dist, list):
        for row in lat_dist:
            if row.get("percentage") == percentile:
                v = row.get("latency")
                if v is None:
                    return None
                return float(v) / 1_000_000.0
    return None


def parse_grpc(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None

    lat = data.get("latencyDistribution") or {}
    err = data.get("errorRatio")
    if err is None:
        ed = data.get("errorDistribution") or {}
        n = int(data.get("count") or 0)
        err = sum(float(v) for v in ed.values()) / float(n) if n and ed else 0.0

    return {
        "lat_p50": grpc_latency_ms(lat, 50),
        "lat_p95": grpc_latency_ms(lat, 95),
        "lat_p99": grpc_latency_ms(lat, 99),
        "rps": data.get("rps"),
        "err": err,
    }


def parse_rest_payload(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None
    m = data.get("metrics", {})
    received = m.get("data_received", {}).get("count")
    reqs = m.get("http_reqs", {}).get("count")
    if received and reqs and float(reqs) > 0:
        return float(received) / float(reqs)
    return None


GRPC_EST_BYTES = 153
EVENTS_PER_MIN = 10_000
MINUTES_PER_YEAR = 60 * 24 * 365


rest_files = sorted(glob.glob(os.path.join(rest_dir, f"{ts}-scenario-*.json")))
grpc_files = sorted(glob.glob(os.path.join(grpc_dir, f"{ts}-scenario-*.json")))

rest_rows = []
for path in rest_files:
    scenario = os.path.basename(path).split("-scenario-")[1].replace(".json", "").upper()
    rest_rows.append({"scenario": scenario, "parsed": parse_rest(path)})

grpc_rows = []
for path in grpc_files:
    scenario = os.path.basename(path).split("-scenario-")[1].replace(".json", "").upper()
    grpc_rows.append({"scenario": scenario, "parsed": parse_grpc(path)})

rest_a_path = os.path.join(rest_dir, f"{ts}-scenario-a.json")
rest_a_bytes = parse_rest_payload(rest_a_path) if os.path.exists(rest_a_path) else None

generated_at = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")


def render_markdown():
    lines = [
        "# Rapport benchmark (latest)",
        "",
        f"- Timestamp: `{ts}`",
        f"- Genere le: `{generated_at} UTC`",
        "",
    ]

    if rest_rows:
        lines.append("## REST")
        lines.append("")
        lines.append("| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |")
        lines.append("|---|---:|---:|---:|---:|---:|")
        for row in rest_rows:
            scenario = row["scenario"]
            parsed = row["parsed"]
            if parsed is None:
                lines.append(f"| {scenario} | n/a | n/a | n/a | n/a | n/a |")
                continue
            lines.append(
                f"| {scenario} | {fmt_num(parsed['lat_p50'])} | {fmt_num(parsed['lat_p95'])} | "
                f"{fmt_num(parsed['lat_p99'])} | {fmt_num(parsed['rps'])} | {fmt_pct(parsed['err'])} |"
            )
        lines.append("")
    else:
        lines.extend(["## REST", "", "_Aucun resultat REST pour ce timestamp._", ""])

    if grpc_rows:
        lines.append("## gRPC")
        lines.append("")
        lines.append("| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |")
        lines.append("|---|---:|---:|---:|---:|---:|")
        for row in grpc_rows:
            scenario = row["scenario"]
            parsed = row["parsed"]
            if parsed is None:
                lines.append(f"| {scenario} | n/a | n/a | n/a | n/a | n/a |")
                continue
            lines.append(
                f"| {scenario} | {fmt_num(parsed['lat_p50'])} | {fmt_num(parsed['lat_p95'])} | "
                f"{fmt_num(parsed['lat_p99'])} | {fmt_num(parsed['rps'])} | {fmt_pct(parsed['err'])} |"
            )
        lines.append("")
    else:
        lines.extend(["## gRPC", "", "_Aucun resultat gRPC pour ce timestamp._", ""])

    lines.append("## Eco-conception : taille des payloads")
    lines.append("")
    if rest_a_bytes is not None:
        ratio = rest_a_bytes / GRPC_EST_BYTES
        rest_min = EVENTS_PER_MIN * rest_a_bytes / 1_000_000
        grpc_min = EVENTS_PER_MIN * GRPC_EST_BYTES / 1_000_000
        rest_yr = rest_min * MINUTES_PER_YEAR / 1_000
        grpc_yr = grpc_min * MINUTES_PER_YEAR / 1_000
        saving_yr = rest_yr - grpc_yr
        lines.extend([
            "| Protocole | Taille reponse GET /sensor (mesuree) | Source |",
            "|---|---:|---|",
            f"| REST (JSON + HTTP/1.1) | {rest_a_bytes:.0f} B/req | k6 data_received / http_reqs |",
            f"| gRPC (Protobuf + HTTP/2) | ~{GRPC_EST_BYTES} B/req | estimation schema .proto |",
            f"| Ratio REST/gRPC | **{ratio:.1f}x** | — |",
            "",
            f"> Extrapolation SignalWatch ({EVENTS_PER_MIN:,} evenements/min, 24h/24, 365j/an)",
            ">",
            "> | Protocole | Bande passante/min | Par an |",
            "> |---|---:|---:|",
            f"> | REST | {rest_min:.2f} MB/min | {rest_yr:.0f} GB/an |",
            f"> | gRPC | {grpc_min:.2f} MB/min | {grpc_yr:.0f} GB/an |",
            f"> | **Economie gRPC** | {rest_min - grpc_min:.2f} MB/min | **{saving_yr:.0f} GB/an** |",
            "",
            "> _Note : la taille REST inclut les en-tetes HTTP/1.1 (~150 B) + corps JSON (~260 B).",
            "> La taille gRPC est une estimation : corps Protobuf (~123 B) + en-tetes HTTP/2 HPACK (~30 B).",
            "> La mesure exacte des octets gRPC necessite un proxy reseau (tcpdump/Wireshark)._",
        ])
    else:
        lines.append("_Donnees de payload non disponibles pour ce timestamp._")
    lines.append("")

    return "\n".join(lines) + "\n"


def html_table_rows(rows):
    rendered = []
    for row in rows:
        scenario = html.escape(row["scenario"])
        parsed = row["parsed"]
        if parsed is None:
            cells = ["n/a", "n/a", "n/a", "n/a", "n/a"]
        else:
            cells = [
                fmt_num(parsed["lat_p50"]),
                fmt_num(parsed["lat_p95"]),
                fmt_num(parsed["lat_p99"]),
                fmt_num(parsed["rps"]),
                fmt_pct(parsed["err"]),
            ]
        rendered.append(
            "<tr>"
            f"<td>{scenario}</td>"
            f"<td class=\"num\">{html.escape(cells[0])}</td>"
            f"<td class=\"num\">{html.escape(cells[1])}</td>"
            f"<td class=\"num\">{html.escape(cells[2])}</td>"
            f"<td class=\"num\">{html.escape(cells[3])}</td>"
            f"<td class=\"num\">{html.escape(cells[4])}</td>"
            "</tr>"
        )
    return "\n".join(rendered)


def render_html():
    escaped_ts = html.escape(ts)
    escaped_generated_at = html.escape(generated_at)
    if rest_a_bytes is not None:
        ratio = rest_a_bytes / GRPC_EST_BYTES
        rest_min = EVENTS_PER_MIN * rest_a_bytes / 1_000_000
        grpc_min = EVENTS_PER_MIN * GRPC_EST_BYTES / 1_000_000
        rest_yr = rest_min * MINUTES_PER_YEAR / 1_000
        grpc_yr = grpc_min * MINUTES_PER_YEAR / 1_000
        saving_yr = rest_yr - grpc_yr
        eco_block = (
            "<table><thead><tr>"
            "<th>Protocole</th><th>Taille reponse GET /sensor</th><th>Source</th>"
            "</tr></thead><tbody>"
            f"<tr><td>REST (JSON + HTTP/1.1)</td>"
            f"<td class=\"num\">{rest_a_bytes:.0f} B/req</td>"
            f"<td>k6 data_received / http_reqs</td></tr>"
            f"<tr><td>gRPC (Protobuf + HTTP/2)</td>"
            f"<td class=\"num\">~{GRPC_EST_BYTES} B/req</td>"
            f"<td>estimation schema .proto</td></tr>"
            f"<tr><td><strong>Ratio REST/gRPC</strong></td>"
            f"<td class=\"num\"><strong>{ratio:.1f}x</strong></td><td>—</td></tr>"
            "</tbody></table>"
            f"<p><em>Extrapolation SignalWatch ({EVENTS_PER_MIN:,} evenements/min, 24h/24, 365j/an)</em></p>"
            "<table><thead><tr>"
            "<th>Protocole</th><th>Bande passante/min</th><th>Par an</th>"
            "</tr></thead><tbody>"
            f"<tr><td>REST</td><td class=\"num\">{rest_min:.2f} MB/min</td><td class=\"num\">{rest_yr:.0f} GB/an</td></tr>"
            f"<tr><td>gRPC</td><td class=\"num\">{grpc_min:.2f} MB/min</td><td class=\"num\">{grpc_yr:.0f} GB/an</td></tr>"
            f"<tr><td><strong>Economie gRPC</strong></td>"
            f"<td class=\"num\">{rest_min - grpc_min:.2f} MB/min</td>"
            f"<td class=\"num\"><strong>{saving_yr:.0f} GB/an</strong></td></tr>"
            "</tbody></table>"
            "<p class=\"meta\"><em>Note : la taille REST inclut les en-tetes HTTP/1.1 (~150 B) + corps JSON (~260 B). "
            "La taille gRPC est une estimation : corps Protobuf (~123 B) + en-tetes HTTP/2 HPACK (~30 B).</em></p>"
        )
    else:
        eco_block = "<p class=\"empty\"><em>Donnees de payload non disponibles pour ce timestamp.</em></p>"
    rest_block = (
        "<p class=\"empty\"><em>Aucun resultat REST pour ce timestamp.</em></p>"
        if not rest_rows
        else (
            "<table><thead><tr>"
            "<th>Scenario</th><th>p50 (ms)</th><th>p95 (ms)</th><th>p99 (ms)</th>"
            "<th>Throughput (req/s)</th><th>Erreurs</th>"
            "</tr></thead><tbody>"
            f"{html_table_rows(rest_rows)}"
            "</tbody></table>"
        )
    )
    grpc_block = (
        "<p class=\"empty\"><em>Aucun resultat gRPC pour ce timestamp.</em></p>"
        if not grpc_rows
        else (
            "<table><thead><tr>"
            "<th>Scenario</th><th>p50 (ms)</th><th>p95 (ms)</th><th>p99 (ms)</th>"
            "<th>Throughput (req/s)</th><th>Erreurs</th>"
            "</tr></thead><tbody>"
            f"{html_table_rows(grpc_rows)}"
            "</tbody></table>"
        )
    )

    return f"""<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Rapport benchmark (latest)</title>
  <style>
    :root {{
      color-scheme: light dark;
      --bg: #f5f7fb;
      --fg: #1b2430;
      --card: #ffffff;
      --border: #d8dee9;
      --muted: #4f5b66;
      --header: #eef3ff;
      --row-alt: #f9fbff;
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{
        --bg: #0f141b;
        --fg: #e6edf3;
        --card: #151b23;
        --border: #2a3441;
        --muted: #9fb0c0;
        --header: #1f2937;
        --row-alt: #111923;
      }}
    }}
    body {{
      margin: 0;
      background: var(--bg);
      color: var(--fg);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.5;
    }}
    .container {{
      max-width: 1024px;
      margin: 2rem auto;
      padding: 0 1rem 2rem;
    }}
    .card {{
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 1.25rem;
      box-shadow: 0 4px 16px rgba(15, 23, 42, 0.06);
    }}
    h1, h2 {{
      margin: 0 0 0.75rem;
      line-height: 1.25;
    }}
    h2 {{
      margin-top: 1.75rem;
    }}
    .meta {{
      margin: 0 0 0.25rem;
      color: var(--muted);
    }}
    code {{
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
      font-size: 0.9em;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 0.5rem;
      font-size: 0.95rem;
    }}
    th, td {{
      border: 1px solid var(--border);
      padding: 0.55rem 0.7rem;
      text-align: left;
    }}
    th {{
      background: var(--header);
      font-weight: 600;
    }}
    tbody tr:nth-child(even) {{
      background: var(--row-alt);
    }}
    td.num {{
      text-align: right;
      font-variant-numeric: tabular-nums;
    }}
    .empty {{
      color: var(--muted);
      margin: 0.35rem 0 0;
    }}
  </style>
</head>
<body>
  <main class="container">
    <section class="card">
      <h1>Rapport benchmark (latest)</h1>
      <p class="meta">Timestamp: <code>{escaped_ts}</code></p>
      <p class="meta">Genere le: <code>{escaped_generated_at} UTC</code></p>
      <h2>REST</h2>
      {rest_block}
      <h2>gRPC</h2>
      {grpc_block}
      <h2>Eco-conception : taille des payloads</h2>
      {eco_block}
    </section>
  </main>
</body>
</html>
"""

with open(output_path, "w", encoding="utf-8") as f:
    f.write(render_markdown())

with open(html_output_path, "w", encoding="utf-8") as f:
    f.write(render_html())

print(output_path)
print(html_output_path)
PY
