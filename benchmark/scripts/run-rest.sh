#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/benchmark/scripts/rest-scenarios.js"
RESULTS_ROOT="${ROOT_DIR}/benchmark/results/rest"

REST_BASE_URL="${REST_BASE_URL:-http://127.0.0.1:8080}"
BENCH_TIMESTAMP="${BENCH_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

A_REQUESTS="${A_REQUESTS:-1000}"
A_CONCURRENCY="${A_CONCURRENCY:-10}"

B_REQUESTS="${B_REQUESTS:-500}"
B_CONCURRENCY="${B_CONCURRENCY:-5}"

C_START_CONCURRENCY="${C_START_CONCURRENCY:-10}"
C_MID_CONCURRENCY="${C_MID_CONCURRENCY:-50}"
C_END_CONCURRENCY="${C_END_CONCURRENCY:-100}"
C_STAGE_1_DURATION="${C_STAGE_1_DURATION:-20s}"
C_STAGE_2_DURATION="${C_STAGE_2_DURATION:-20s}"
C_STAGE_3_DURATION="${C_STAGE_3_DURATION:-20s}"
C_STAGE_4_DURATION="${C_STAGE_4_DURATION:-10s}"

mkdir -p "${RESULTS_ROOT}"

wait_for_rest() {
  local retries=30
  local delay=1

  if ! command -v k6 >/dev/null 2>&1; then
    echo "k6 is required but was not found in PATH" >&2
    exit 1
  fi

  for ((i = 1; i <= retries; i++)); do
    if curl -sS --max-time 2 "${REST_BASE_URL}/sensors" >/dev/null; then
      return 0
    fi
    sleep "${delay}"
  done

  echo "REST service is not reachable at ${REST_BASE_URL}" >&2
  exit 1
}

run_scenario() {
  local scenario="$1"
  local output_file="$2"
  shift 2

  k6 run "${SCRIPT_PATH}" \
    -e REST_BASE_URL="${REST_BASE_URL}" \
    -e BENCH_SCENARIO="${scenario}" \
    -e BENCH_TIMESTAMP="${BENCH_TIMESTAMP}" \
    --summary-export "${output_file}" \
    "$@"
}

wait_for_rest

run_scenario "A" "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-a.json" \
  --vus "${A_CONCURRENCY}" \
  --iterations "${A_REQUESTS}"

run_scenario "B" "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-b.json" \
  --vus "${B_CONCURRENCY}" \
  --iterations "${B_REQUESTS}"

run_scenario "C" "${RESULTS_ROOT}/${BENCH_TIMESTAMP}-scenario-c.json" \
  -e C_START_CONCURRENCY="${C_START_CONCURRENCY}" \
  -e C_MID_CONCURRENCY="${C_MID_CONCURRENCY}" \
  -e C_END_CONCURRENCY="${C_END_CONCURRENCY}" \
  -e C_STAGE_1_DURATION="${C_STAGE_1_DURATION}" \
  -e C_STAGE_2_DURATION="${C_STAGE_2_DURATION}" \
  -e C_STAGE_3_DURATION="${C_STAGE_3_DURATION}" \
  -e C_STAGE_4_DURATION="${C_STAGE_4_DURATION}"
