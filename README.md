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
# Lancer le service REST (port 3000)
cargo run -p rest-service

# Lancer le service gRPC (port 50051)
cargo run -p grpc-service
```

### Lancer les benchmarks (tout en une commande)

```bash
make benchmark-all
```

---

## Scenarios de benchmark

| Scenario | Description | Requetes | Concurrence |
|----------|-------------|----------|-------------|
| A - Lecture unitaire | GET /sensors/:id vs GetSensor | 1 000 | 10 |
| B - Ecriture | POST /sensors vs CreateSensor | 500 | 5 |
| C - Charge progressive | Montee de 10 a 100 connexions | variable | 10 -> 100 |

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

---

## Securite

Consulter [SECURITY.md](./SECURITY.md) pour signaler une vulnerabilite.

---

## Licence

Ce projet est sous licence [MIT](./LICENSE).
