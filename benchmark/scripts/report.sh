#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REST_DIR="${ROOT_DIR}/benchmark/results/rest"
GRPC_DIR="${ROOT_DIR}/benchmark/results/grpc"
OUTPUT_PATH="${ROOT_DIR}/benchmark/results/report-latest.md"

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

python3 - "${ROOT_DIR}" "${LATEST_TIMESTAMP}" "${OUTPUT_PATH}" <<'PY'
import glob
import json
import os
import sys
from datetime import datetime

root_dir, ts, output_path = sys.argv[1], sys.argv[2], sys.argv[3]

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


rest_files = sorted(glob.glob(os.path.join(rest_dir, f"{ts}-scenario-*.json")))
grpc_files = sorted(glob.glob(os.path.join(grpc_dir, f"{ts}-scenario-*.json")))

lines = [
    "# Rapport benchmark (latest)",
    "",
    f"- Timestamp: `{ts}`",
    f"- Genere le: `{datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC`",
    "",
]

if rest_files:
    lines.append("## REST")
    lines.append("")
    lines.append("| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for path in rest_files:
        scenario = os.path.basename(path).split("-scenario-")[1].replace(".json", "").upper()
        parsed = parse_rest(path)
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

if grpc_files:
    lines.append("## gRPC")
    lines.append("")
    lines.append("| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for path in grpc_files:
        scenario = os.path.basename(path).split("-scenario-")[1].replace(".json", "").upper()
        parsed = parse_grpc(path)
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

with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(output_path)
PY
