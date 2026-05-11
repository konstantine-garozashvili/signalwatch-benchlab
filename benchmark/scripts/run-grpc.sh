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

run_ghz() {
  ghz --plaintext \
    --proto "${PROTO_PATH}" \
    --call "$1" \
    --total "$2" \
    --concurrency "$3" \
    --data-file "$4" \
    --format json \
    --output "$5" \
    "${GRPC_HOST}"
}

extract_seed_sensor_id() {
  local seed_output="$1"
  python3 - "$seed_output" <<'PY'
import json
import re
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = f.read()

try:
    parsed = json.loads(data)
except json.JSONDecodeError:
    parsed = None

if parsed is not None:
    stack = [parsed]
    while stack:
        item = stack.pop()
        if isinstance(item, dict):
            for key, value in item.items():
                if key == "id" and isinstance(value, str):
                    print(value)
                    sys.exit(0)
                stack.append(value)
        elif isinstance(item, list):
            stack.extend(item)

match = re.search(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", data)
if match:
    print(match.group(0))
    sys.exit(0)

print("Unable to extract sensor id from seed output", file=sys.stderr)
sys.exit(1)
PY
}

prepare_payload_with_sensor_id() {
  local template_path="$1"
  local sensor_id="$2"
  local output_path="$3"
  sed "s/__SENSOR_ID__/${sensor_id}/g" "${template_path}" >"${output_path}"
}

wait_for_grpc

seed_output="${RESULTS_ROOT}/${BENCH_TIMESTAMP}-seed-create.json"
run_ghz \
  "signalwatch.sensor.v1.SensorService/CreateSensor" \
  "1" \
  "1" \
  "${GRPC_PAYLOAD_DIR}/scenario-b-createsensor.json" \
  "${seed_output}"

SENSOR_ID="${SENSOR_ID:-$(extract_seed_sensor_id "${seed_output}")}"

scenario_a_payload="$(mktemp)"
scenario_c_payload="$(mktemp)"
trap 'rm -f "${scenario_a_payload}" "${scenario_c_payload}"' EXIT

prepare_payload_with_sensor_id "${GRPC_PAYLOAD_DIR}/scenario-a-getsensor.json" "${SENSOR_ID}" "${scenario_a_payload}"
prepare_payload_with_sensor_id "${GRPC_PAYLOAD_DIR}/scenario-c-ramp.json" "${SENSOR_ID}" "${scenario_c_payload}"

run_ghz \
  "signalwatch.sensor.v1.SensorService/GetSensor" \
  "${A_REQUESTS}" \
  "${A_CONCURRENCY}" \
  "${scenario_a_payload}" \
  "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-a.json"

run_ghz \
  "signalwatch.sensor.v1.SensorService/CreateSensor" \
  "${B_REQUESTS}" \
  "${B_CONCURRENCY}" \
  "${GRPC_PAYLOAD_DIR}/scenario-b-createsensor.json" \
  "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-b.json"

for concurrency in $(seq "${C_START_CONCURRENCY}" "${C_CONCURRENCY_STEP}" "${C_END_CONCURRENCY}"); do
  run_ghz \
    "signalwatch.sensor.v1.SensorService/GetSensor" \
    "${C_REQUESTS_PER_STEP}" \
    "${concurrency}" \
    "${scenario_c_payload}" \
    "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-c-concurrency-${concurrency}.json"
done
