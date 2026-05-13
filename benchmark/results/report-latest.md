# Rapport benchmark (latest)

- Timestamp: `20260513-091258`
- Genere le: `2026-05-13 07:43:06 UTC`

## REST

| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |
|---|---:|---:|---:|---:|---:|
| A | 0.15 | 0.34 | n/a | 42030.57 | 0.00% |
| B | 0.14 | 0.26 | n/a | 24575.69 | 0.00% |
| C | 0.43 | 1.31 | n/a | 70297.51 | 0.00% |

## gRPC

| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |
|---|---:|---:|---:|---:|---:|
| A | 0.48 | 0.78 | 1.11 | 16112.96 | 0.00% |
| B | 0.22 | 0.36 | 0.46 | 16921.33 | 0.00% |
| C-CONCURRENCY-10 | 0.44 | 0.69 | 0.80 | 17526.82 | 0.00% |
| C-CONCURRENCY-100 | 4.53 | 7.17 | 8.12 | 15205.46 | 0.00% |
| C-CONCURRENCY-20 | 0.87 | 1.32 | 1.40 | 18345.82 | 0.00% |
| C-CONCURRENCY-30 | 1.26 | 2.39 | 3.09 | 18070.32 | 0.00% |
| C-CONCURRENCY-40 | 1.71 | 2.38 | 2.48 | 17979.41 | 0.00% |
| C-CONCURRENCY-50 | 2.44 | 2.99 | 3.15 | 16668.35 | 0.00% |
| C-CONCURRENCY-60 | 2.63 | 3.33 | 3.75 | 17680.41 | 0.00% |
| C-CONCURRENCY-70 | 2.84 | 5.34 | 5.63 | 16786.86 | 0.00% |
| C-CONCURRENCY-80 | 3.67 | 5.23 | 5.96 | 17576.82 | 0.00% |
| C-CONCURRENCY-90 | 4.15 | 6.85 | 8.39 | 15425.65 | 0.00% |

## Eco-conception : taille des payloads

| Protocole | Taille reponse GET /sensor (mesuree) | Source |
|---|---:|---|
| REST (JSON + HTTP/1.1) | 410 B/req | k6 data_received / http_reqs |
| gRPC (Protobuf + HTTP/2) | ~153 B/req | estimation schema .proto |
| Ratio REST/gRPC | **2.7x** | — |

> Extrapolation SignalWatch (10,000 evenements/min, 24h/24, 365j/an)
>
> | Protocole | Bande passante/min | Par an |
> |---|---:|---:|
> | REST | 4.10 MB/min | 2155 GB/an |
> | gRPC | 1.53 MB/min | 804 GB/an |
> | **Economie gRPC** | 2.57 MB/min | **1351 GB/an** |

> _Note : la taille REST inclut les en-tetes HTTP/1.1 (~150 B) + corps JSON (~260 B).
> La taille gRPC est une estimation : corps Protobuf (~123 B) + en-tetes HTTP/2 HPACK (~30 B).
> La mesure exacte des octets gRPC necessite un proxy reseau (tcpdump/Wireshark)._

