# SignalWatch BenchLab

> Veille strategique et benchmark technique : REST vs gRPC pour une plateforme IoT industrielle
> Microservices implementes en **Rust** | Benchmarks reproductibles | Analyse eco-conception

---

## Contexte

Ce depot est realise dans le cadre d'une mission de conseil technique pour **SignalWatch**, une startup IoT en pleine levee de fonds. La plateforme collecte des donnees de capteurs industriels (temperature, pression, vibration) a raison de **10 000 evenements par minute**.

L'objectif est de comparer deux protocoles de communication inter-services :
- **REST / HTTP** - implementation avec [Axum](https://github.com/tokio-rs/axum)
- **gRPC / HTTP2** - implementation avec [Tonic](https://github.com/hyperium/tonic)

---

## Structure du depot

```
signalwatch-benchlab/
|-- rest-service/          # Micro-service REST (Axum + Tokio)
|-- grpc-service/          # Micro-service gRPC (Tonic + Prost)
|-- common/                # Modeles de donnees partages
|-- proto/                 # Fichiers .proto (definition gRPC)
|-- benchmark/
|   |-- scripts/           # Scripts k6 / hey / ghz
|   |-- results/           # Resultats bruts (CSV, JSON)
|-- docs/
|   |-- rapport-veille.pdf # Rapport de veille 8-10 pages
|   |-- presentation.pdf   # Support de presentation
|-- plan-veille.md         # Plan de veille + RACI
|-- Makefile               # Orchestration : build, bench, rapport
|-- README.md
|-- CONTRIBUTING.md
|-- SECURITY.md
|-- LICENSE
```

---

## Prerequis

- [Rust](https://www.rust-lang.org/) >= 1.78 (edition 2021)
- [Docker](https://www.docker.com/) >= 24
- [Protocol Buffers compiler](https://grpc.io/docs/protoc-installation/) (`protoc`)
- [k6](https://k6.io/) ou [hey](https://github.com/rakyll/hey) pour les benchmarks REST
- [ghz](https://ghz.sh/) pour les benchmarks gRPC

---

## Installation et lancement

### Cloner le depot

```bash
git clone https://github.com/konstantine-garozashvili/signalwatch-benchlab.git
cd signalwatch-benchlab
```

### Lancer les services

```bash
# Lancer REST + gRPC en une commande
make run
```

### Lancer les benchmarks (tout en une commande)

```bash
make bench
```

Commandes disponibles:

```bash
make run
make bench
make report
make benchmark-rest
make benchmark-grpc
make benchmark-all
```

Les scripts utilisent:
- `benchmark/scripts/run-rest.sh`
- `benchmark/scripts/run-grpc.sh`
- `benchmark/scripts/run-all.sh`

Les resultats sont exportes automatiquement sous:
- `benchmark/results/rest`
- `benchmark/results/grpc`

Un rapport consolide est genere via:

```bash
make report
```

Fichier de sortie:
- `benchmark/results/report-latest.md`

---

## Livrables documentaires

- [Rapport de veille](./docs/rapport-veille.pdf) - synthese ecrite (contexte, methode, analyse).
- [Presentation](./docs/presentation.pdf) - support de restitution condense.
- [Guide de reproduction des benchmarks](./docs/benchmark-reproduction.md) — runbook contributeur (`make run`, `make bench`, `make report`).

Rapport Markdown genere apres coup : [benchmark/results/report-latest.md](./benchmark/results/report-latest.md).

---

## Resultats benchmark (instantane de reference)

Un jeu de resultats complet est archive sous le suffixe de fichiers **`20260512-signalwatch-final`** (execution du 12 mai 2026 sur environnement de developpement ; les valeurs varient selon la machine).

Extraits representatifs (detail et rampe complete dans le rapport) :

| Scenario | REST (indicatif) | gRPC (indicatif) |
|----------|------------------|------------------|
| A - Lecture unitaire | p50 ~0,14 ms ; debit k6 ~43,7k req/s | p50 ~0,46 ms ; debit ghz ~16,3k req/s |
| B - Ecriture | p50 ~0,13 ms ; debit k6 ~24,3k req/s | p50 ~0,22 ms ; debit ghz ~15,6k req/s |
| C - Charge progressive | debit agrege k6 ~54,9k req/s sur la rampe testee | plusieurs fichiers `scenario-c-concurrency-*.json` ; p50 monte avec la concurrence (ex. ~4,8 ms a 100 connexions pour la derniere etape) |

Les debits **k6** et **ghz** ne sont pas comparables comme un classement absolu : ils reflectent chaque outil et scenario. Utiliser surtout les latences et la stabilite des erreurs pour comparer les stacks dans ce depot.

---

## Recommandations

- **REST** lorsque l'API doit rester accessible aux integrations HTTP classiques (reverse proxy, cache, outillage curl/OpenAPI) et lorsque l'equipe privilegie la lisibilite JSON et la velocite d'onboarding.
- **gRPC** lorsque le contrat Protobuf est pilote par plusieurs equipes, que les messages compacts et HTTP/2 sont importants, et que la generation de code et `protoc` sont acceptees dans la chaine de livraison.
- **Validation continue** : rejouer `make bench` avec un `BENCH_TIMESTAMP` fixe lors des changements critiques ; traiter les rapports comme indicatifs avant dimensionnement production.

---

## Scenarios de benchmark

| Scenario | Description | Requetes | Concurrence |
|----------|-------------|----------|-------------|
| A - Lecture unitaire | GET /sensors/:id vs GetSensor | 1 000 | 10 |
| B - Ecriture | POST /sensors vs CreateSensor | 500 | 5 |
| C - Charge progressive | Montee de 10 a 100 connexions | variable | 10 -> 100 |

### Parametrage (variables d'environnement)

Variables communes:
- `BENCH_TIMESTAMP` : suffixe des fichiers de resultats (defaut: date courante `YYYYMMDD-HHMMSS`)
- `A_REQUESTS` / `A_CONCURRENCY` : scenario A (defaut: `1000` / `10`)
- `B_REQUESTS` / `B_CONCURRENCY` : scenario B (defaut: `500` / `5`)
- `C_START_CONCURRENCY` / `C_END_CONCURRENCY` : scenario C (defaut: `10` / `100`)

Variables REST:
- `REST_BASE_URL` (defaut: `http://127.0.0.1:8080`)
- `C_MID_CONCURRENCY` (defaut: `50`)
- `C_STAGE_1_DURATION`, `C_STAGE_2_DURATION`, `C_STAGE_3_DURATION`, `C_STAGE_4_DURATION`

Variables gRPC:
- `GRPC_HOST` (defaut: `127.0.0.1:50051`)
- `C_CONCURRENCY_STEP` (defaut: `10`)
- `C_REQUESTS_PER_STEP` (defaut: `200`)
- `SENSOR_ID` (optionnel, sinon seed automatique via `CreateSensor`)

Exemple:

```bash
A_REQUESTS=2000 A_CONCURRENCY=20 make benchmark-rest
GRPC_HOST=127.0.0.1:50051 C_REQUESTS_PER_STEP=400 make benchmark-grpc
```

### Metriques collectees

- Latence p50 / p95 / p99 (ms)
- Throughput (req/s)
- Taille moyenne des payloads (octets)
- Taux d'erreur (%)
- Consommation CPU / RAM

---

## Modele de donnees : Capteur (Sensor)

```rust
pub struct Sensor {
    pub id: Uuid,              // Identifiant unique (genere cote serveur)
    pub name: String,          // Ex : "Turbine-A3-Temp"
    pub sensor_type: SensorType, // TEMPERATURE | PRESSURE | VIBRATION
    pub location: String,      // Ex : "Batiment C - Salle 12"
    pub unit: String,          // Ex : "C", "bar", "mm/s"
    pub status: SensorStatus,  // ACTIVE | INACTIVE | MAINTENANCE
    pub last_value: f64,       // Derniere valeur mesuree
    pub last_reading_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}
```

---

## Operations CRUD disponibles

| Operation | REST | gRPC |
|-----------|------|------|
| Creer un capteur | POST /sensors | CreateSensor |
| Lister les capteurs | GET /sensors | ListSensors |
| Lire un capteur | GET /sensors/:id | GetSensor |
| Mettre a jour | PUT /sensors/:id | UpdateSensor |
| Supprimer | DELETE /sensors/:id | DeleteSensor |

---

## Alignement REST et gRPC pour le benchmark

Pour garantir une comparaison juste entre les deux services, les regles metier et les categories d'erreur sont alignees sur les memes cas fonctionnels.

- Valeurs enum `unspecified` refusees pour `sensor_type` (create/update) et `status` (update)
- Identifiant invalide:
  - REST: `400 Bad Request`
  - gRPC: `InvalidArgument`
- Ressource absente:
  - REST: `404 Not Found`
  - gRPC: `NotFound`
- Payload/mapping invalide:
  - REST: `400 Bad Request`
  - gRPC: `InvalidArgument`

Les tests d'integration de `rest-service` et `grpc-service` couvrent ces cas de conformance en plus du flux CRUD nominal.

---

## Contrat gRPC (proto)

Le contrat gRPC est defini dans `proto/sensor.proto`.

- Package: `signalwatch.sensor.v1`
- Service: `SensorService`
- RPC:
  - `CreateSensor`: creer un capteur
  - `ListSensors`: lister tous les capteurs
  - `GetSensor`: lire un capteur par identifiant
  - `UpdateSensor`: mettre a jour un capteur
  - `DeleteSensor`: supprimer un capteur

La generation du code Rust (Tonic/Prost) est configuree via `grpc-service/build.rs`.

```bash
# Verifier la compilation et generer le code depuis le proto
cargo check -p grpc-service

# Compilation complete avec generation proto
cargo build -p grpc-service
```

---

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Langage | Rust (edition 2021) |
| Framework REST | Axum + Tokio |
| Framework gRPC | Tonic + Prost |
| Stockage | Memoire partagee (DashMap) ou SQLite |
| Serialisation | JSON (REST) / Protobuf (gRPC) |
| Tests de charge | k6, hey, ghz |
| CI/CD | GitHub Actions |
| Conteneurisation | Docker + Docker Compose |

---

## Contribution

Consulter [CONTRIBUTING.md](./CONTRIBUTING.md) pour les conventions de commits, la strategie de branches et le processus de revue de code.

## Qualite et CI

La CI GitHub Actions execute les controles suivants sur `main` et `develop`:
- `cargo fmt --all -- --check`
- `cargo clippy --all-targets --all-features -- -D warnings`
- `cargo test --all --verbose`

Verification locale recommandee avant une PR:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all --verbose
```

---

## Securite

Consulter [SECURITY.md](./SECURITY.md) pour signaler une vulnerabilite.

---

## Licence

Ce projet est sous licence [MIT](./LICENSE).
