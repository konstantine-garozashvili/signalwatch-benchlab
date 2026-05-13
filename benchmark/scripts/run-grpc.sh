#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROTO_PATH="${ROOT_DIR}/proto/sensor.proto"
GRPC_PAYLOAD_DIR="${ROOT_DIR}/benchmark/scripts/grpc"
RESULTS_ROOT="${ROOT_DIR}/benchmark/results/grpc"

GRPC_HOST="${GRPC_HOST:-127.0.0.1:50051}"
BENCH_TIMESTAMP="${BENCH_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

A_REQUESTS="${A_REQUESTS:-1000}"
A_CONCURRENCY="${A_CONCURRENCY:-10}"

B_REQUESTS="${B_REQUESTS:-500}"
B_CONCURRENCY="${B_CONCURRENCY:-5}"

C_START_CONCURRENCY="${C_START_CONCURRENCY:-10}"
C_END_CONCURRENCY="${C_END_CONCURRENCY:-100}"
C_CONCURRENCY_STEP="${C_CONCURRENCY_STEP:-10}"
C_REQUESTS_PER_STEP="${C_REQUESTS_PER_STEP:-200}"

mkdir -p "${RESULTS_ROOT}"

wait_for_grpc() {
  local retries=30
  local delay=1

  if ! command -v ghz >/dev/null 2>&1; then
    echo "ghz is required but was not found in PATH" >&2
    exit 1
  fi

  for ((i = 1; i <= retries; i++)); do
    if python3 - "${GRPC_HOST}" <<'PY'
import socket
import sys

host, port = sys.argv[1].rsplit(":", 1)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(1)
try:
    s.connect((host, int(port)))
except OSError:
    sys.exit(1)
finally:
    s.close()
sys.exit(0)
PY
    then
      return 0
    fi
    sleep "${delay}"
  done

  echo "gRPC service is not reachable at ${GRPC_HOST}" >&2
  exit 1
}

print_grpc_summary() {
  local label="$1"
  local file="$2"
  python3 - "${label}" "${file}" <<'PY'
import json
import sys

label, path = sys.argv[1], sys.argv[2]
with open(path) as f:
    d = json.load(f)


def latency(percentile):
    for row in d.get("latencyDistribution") or []:
        if row.get("percentage") == percentile:
            v = row.get("latency")
            return v / 1_000_000 if v is not None else None
    return None


def fmt(v):
    if v is None:
        return "n/a"
    if v >= 1:
        return f"{v:.2f}ms"
    return f"{v * 1000:.0f}\u00b5s"


count = int(d.get("count") or 0)
rps = float(d.get("rps") or 0.0)
fastest = (d.get("fastest") or 0) / 1_000_000
slowest = (d.get("slowest") or 0) / 1_000_000
average = (d.get("average") or 0) / 1_000_000
p50, p95, p99 = latency(50), latency(95), latency(99)
status = d.get("statusCodeDistribution") or {}
errors = sum(int(v) for k, v in status.items() if k != "OK")
err_pct = (errors / count * 100) if count else 0.0

print()
print(f"  \u2588 gRPC {label}")
print()
print(f"    requests..............: {count}    {rps:,.2f}/s")
print(
    f"    latency...............: avg={fmt(average)} min={fmt(fastest)} med={fmt(p50)} "
    f"max={fmt(slowest)} p(95)={fmt(p95)} p(99)={fmt(p99)}"
)
status_str = ", ".join(f"{k}={v}" for k, v in status.items()) or "n/a"
print(f"    status................: {status_str}")
print(f"    errors................: {errors} ({err_pct:.2f}%)")
print()
PY
}

run_ghz() {
  local label="$1"
  local call="$2"
  local total="$3"
  local concurrency="$4"
  local data_file="$5"
  local output_file="$6"

  # Mirror k6's VU model: one TCP connection per in-flight RPC so the
  # comparison with k6 (which opens one socket per VU) is apples-to-apples.
  # ghz default is 1 connection multiplexing all streams, which throttles
  # throughput on loopback. Override with GHZ_CONNECTIONS=N if needed.
  local connections="${GHZ_CONNECTIONS:-${concurrency}}"

  echo ""
  echo "▶ gRPC ${label}  ${call}  (total=${total}, concurrency=${concurrency}, connections=${connections})"

  ghz --insecure \
    --proto "${PROTO_PATH}" \
    --call "${call}" \
    --total "${total}" \
    --concurrency "${concurrency}" \
    --connections "${connections}" \
    --data-file "${data_file}" \
    --format json \
    --output "${output_file}" \
    "${GRPC_HOST}"

  print_grpc_summary "${label}" "${output_file}"
}

seed_sensor_id() {
  if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo is required to seed SENSOR_ID but was not found in PATH" >&2
    exit 1
  fi
  (cd "${ROOT_DIR}" && GRPC_HOST="${GRPC_HOST}" cargo run --quiet -p grpc-service --bin seed_sensor)
}

prepare_payload_with_sensor_id() {
  local template_path="$1"
  local sensor_id="$2"
  local output_path="$3"
  sed "s/__SENSOR_ID__/${sensor_id}/g" "${template_path}" >"${output_path}"
}

wait_for_grpc

SENSOR_ID="${SENSOR_ID:-$(seed_sensor_id)}"

scenario_a_payload="$(mktemp)"
scenario_c_payload="$(mktemp)"
trap 'rm -f "${scenario_a_payload}" "${scenario_c_payload}"' EXIT

prepare_payload_with_sensor_id "${GRPC_PAYLOAD_DIR}/scenario-a-getsensor.json" "${SENSOR_ID}" "${scenario_a_payload}"
prepare_payload_with_sensor_id "${GRPC_PAYLOAD_DIR}/scenario-c-ramp.json" "${SENSOR_ID}" "${scenario_c_payload}"

run_ghz \
  "A - GetSensor" \
  "signalwatch.sensor.v1.SensorService/GetSensor" \
  "${A_REQUESTS}" \
  "${A_CONCURRENCY}" \
  "${scenario_a_payload}" \
  "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-a.json"

run_ghz \
  "B - CreateSensor" \
  "signalwatch.sensor.v1.SensorService/CreateSensor" \
  "${B_REQUESTS}" \
  "${B_CONCURRENCY}" \
  "${GRPC_PAYLOAD_DIR}/scenario-b-createsensor.json" \
  "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-b.json"

for concurrency in $(seq "${C_START_CONCURRENCY}" "${C_CONCURRENCY_STEP}" "${C_END_CONCURRENCY}"); do
  run_ghz \
    "C - GetSensor (concurrency=${concurrency})" \
    "signalwatch.sensor.v1.SensorService/GetSensor" \
    "${C_REQUESTS_PER_STEP}" \
    "${concurrency}" \
    "${scenario_c_payload}" \
    "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-c-concurrency-${concurrency}.json"
done
