.PHONY: help run bench report benchmark-rest benchmark-grpc benchmark-all

help:
	@echo "Targets disponibles:"
	@echo "  run            - Lance les services REST et gRPC"
	@echo "  bench          - Lance la suite de benchmarks (alias benchmark-all)"
	@echo "  report         - Genere un rapport Markdown depuis les derniers resultats"
	@echo "  benchmark-rest - Lance les benchmarks REST (A/B/C)"
	@echo "  benchmark-grpc - Lance les benchmarks gRPC (A/B/C)"
	@echo "  benchmark-all  - Lance tous les benchmarks REST + gRPC"

run:
	@bash -c 'set -euo pipefail; \
	trap "kill 0" EXIT INT TERM; \
	cargo run -p rest-service & \
	cargo run -p grpc-service & \
	wait'

bench: benchmark-all

report:
	@./benchmark/scripts/report.sh

benchmark-rest:
	@./benchmark/scripts/run-rest.sh

benchmark-grpc:
	@./benchmark/scripts/run-grpc.sh

benchmark-all:
	@./benchmark/scripts/run-all.sh
