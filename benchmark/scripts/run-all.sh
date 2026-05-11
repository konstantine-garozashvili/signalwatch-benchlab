#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_TIMESTAMP="${BENCH_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

mkdir -p "${ROOT_DIR}/benchmark/results/rest" "${ROOT_DIR}/benchmark/results/grpc"

BENCH_TIMESTAMP="${BENCH_TIMESTAMP}" "${ROOT_DIR}/benchmark/scripts/run-rest.sh"
BENCH_TIMESTAMP="${BENCH_TIMESTAMP}" "${ROOT_DIR}/benchmark/scripts/run-grpc.sh"
