.PHONY: help benchmark-rest benchmark-grpc benchmark-all

help:
	@echo "Targets disponibles:"
	@echo "  benchmark-rest - Lance les benchmarks REST (A/B/C)"
	@echo "  benchmark-grpc - Lance les benchmarks gRPC (A/B/C)"
	@echo "  benchmark-all  - Lance tous les benchmarks REST + gRPC"

benchmark-rest:
	@./benchmark/scripts/run-rest.sh

benchmark-grpc:
	@./benchmark/scripts/run-grpc.sh

benchmark-all:
	@./benchmark/scripts/run-all.sh
