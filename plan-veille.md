# Plan de veille — REST vs gRPC pour SignalWatch

> **Version complète :** [`docs/plan-veille.md`](./docs/plan-veille.md)
> Ce fichier présente le résumé exécutif. Pour les sources détaillées, le planning complet et la matrice RACI étendue, consulter la version dans `docs/`.

---

## Objectif

Comparer les performances, la robustesse et l'impact opérationnel de deux approches microservices pour la plateforme IoT SignalWatch :

- **REST / HTTP 1.1** — implémenté avec Axum (Rust)
- **gRPC / HTTP2** — implémenté avec Tonic (Rust)

Contexte : 10 000 événements/minute, capteurs industriels (température, pression, vibration), architecture microservices.

---

## Répartition thématique (Qui recherche quoi)

| Membre | Thème principal |
|--------|----------------|
| Konstantine G. (Tech Lead) | Implémentation services + benchmark (k6/ghz/Rust) |
| Membre 2 (Backend) | Protocoles : REST/HTTP, gRPC/HTTP2, GraphQL, Protocol Buffers |
| Membre 3 (QA/PM) | Réglementation : RGPD, RGESN, CNIL IoT, éco-conception |
| Membre 4 (Veille) | Message brokers (Kafka, RabbitMQ) + protocoles IoT émergents (MQTT, CoAP) |

---

## Sources clés par thème (synthèse)

| Thème | Sources principales |
|-------|---------------------|
| gRPC / Protobuf | grpc.io (officiel), Tonic docs, Protocol Buffers Language Guide |
| REST / HTTP | RFC 7540 (HTTP/2), REST API Design Rulebook (O'Reilly), Google Cloud Architecture Center |
| GraphQL | graphql.org (officiel), Apollo documentation |
| Message brokers | Kafka docs (Apache), RabbitMQ docs, Confluent comparatif |
| RGPD IoT | CNIL IoT guidelines, Règlement UE 2016/679, ENISA IoT Security |
| Éco-conception | RGESN (gouvernemental), Green IT rapport, IEEE IoT Protocols Survey |

> Sources complètes (≥ 3 par thème) : voir [`docs/plan-veille.md`](./docs/plan-veille.md#2-sources-par-thème-minimum-3-par-membre)

---

## Planning de la semaine

| Jour | Activité | Livrable |
|------|----------|----------|
| Lundi | Cadrage + setup environnement | Repo initialisé, proto défini |
| Mardi | Implémentation services + veille protocolaire | CRUD REST + gRPC fonctionnel |
| Mercredi | Scripts benchmark + veille réglementaire | Scénarios A/B/C opérationnels, analyse RGPD |
| Jeudi | Exécution benchmarks + veille message brokers | JSON résultats versionnés |
| Vendredi matin | Rapport + présentation | PDF consolidés |
| Vendredi après-midi | Revue finale + dépôt GitHub | Repo complet, tag de release |

---

## Format de restitution interne

- **Point quotidien** (15 min en début de journée) : avancement, blocages
- **Document partagé** (Notion/Google Docs) : notes de veille centralisées par thème
- **Canal dédié** (`#benchlab`) : partage de sources, questions rapides
- **Critère de validation** : chaque section relue par au moins un autre membre

---

## RACI — Matrice de responsabilités

| Livrable | Responsible | Accountable | Consulted | Informed |
|----------|-------------|-------------|-----------|----------|
| Service REST (Axum) | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Service gRPC (Tonic) | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Scripts benchmark (k6/ghz) | Konstantine G. | Konstantine G. | Membre 3 | Tous |
| Résultats bruts JSON | Konstantine G. | Konstantine G. | Membre 3 | Tous |
| Rapport — Panorama protocoles | Membre 2 | Konstantine G. | Membre 4 | Tous |
| Rapport — Résultats benchmark | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Rapport — Éco-conception | Membre 3 | Konstantine G. | Membre 2 | Tous |
| Rapport — Analyse RGPD | Membre 3 | Membre 3 | Konstantine G. | Tous |
| Rapport — Recommandation | Konstantine G. | Konstantine G. | Tous | CTO |
| Support de présentation | Membre 2 + Membre 4 | Konstantine G. | Tous | — |
| README + docs techniques | Konstantine G. | Konstantine G. | Membre 2 | Tous |

**Légende :** R = Responsible | A = Accountable | C = Consulted | I = Informed
