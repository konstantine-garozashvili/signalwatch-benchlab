# Rapport benchmark (latest)

- Timestamp: `20260513-141310`
- Genere le: `2026-05-13 12:14:38 UTC`

## REST

| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |
|---|---:|---:|---:|---:|---:|
| A | 0.08 | 0.18 | n/a | 66212.46 | 0.00% |
| B | 0.07 | 0.16 | n/a | 37948.80 | 0.00% |
| C | 0.16 | 1.01 | n/a | 110378.55 | 0.00% |

## gRPC

| Scenario | p50 (ms) | p95 (ms) | p99 (ms) | Throughput (req/s) | Erreurs |
|---|---:|---:|---:|---:|---:|
| A | 0.20 | 0.45 | 0.70 | 26416.91 | 0.00% |
| B | 0.17 | 0.33 | 0.45 | 19012.22 | 0.00% |
| C-CONCURRENCY-10 | 0.25 | 0.52 | 0.65 | 22760.36 | 0.00% |
| C-CONCURRENCY-100 | 1.39 | 3.88 | 4.98 | 33209.72 | 0.00% |
| C-CONCURRENCY-20 | 0.40 | 1.06 | 1.41 | 26737.97 | 0.00% |
| C-CONCURRENCY-30 | 0.55 | 1.32 | 1.45 | 31087.08 | 0.00% |
| C-CONCURRENCY-40 | 0.79 | 1.61 | 2.01 | 31060.53 | 0.00% |
| C-CONCURRENCY-50 | 1.02 | 3.04 | 3.64 | 26744.38 | 0.00% |
| C-CONCURRENCY-60 | 1.04 | 2.52 | 3.44 | 31089.69 | 0.00% |
| C-CONCURRENCY-70 | 1.72 | 2.83 | 3.02 | 28847.37 | 0.00% |
| C-CONCURRENCY-80 | 1.79 | 3.23 | 3.96 | 28757.50 | 0.00% |
| C-CONCURRENCY-90 | 2.38 | 3.83 | 4.50 | 26231.23 | 0.00% |

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

