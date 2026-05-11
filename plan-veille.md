# Plan de veille - REST vs gRPC

## Objectif

Comparer les performances, la robustesse et l'impact operationnel de deux approches micro-services:

- REST/HTTP (Axum)
- gRPC/HTTP2 (Tonic)

## Perimetre

- Mise en place de deux services equivalents (CRUD capteurs)
- Benchmarks reproductibles (latence, throughput, erreurs)
- Analyse eco-conception (CPU/RAM, taille des payloads)

## RACI (brouillon)

| Activite | R | A | C | I |
|----------|---|---|---|---|
| Conception protocole benchmark | Tech lead | CTO | Equipe backend | Stakeholders |
| Developpement services | Backend | Tech lead | QA | CTO |
| Execution benchmarks | QA | Tech lead | Backend | CTO |
| Rapport final | Tech lead | CTO | Backend, QA | Stakeholders |
