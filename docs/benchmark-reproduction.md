# Guide de reproduction des benchmarks

Ce guide permet a un nouveau contributeur de regenerer les memes types d'artefacts que ceux decrits dans le README (JSON bruts, rapport Markdown consolide).

## Prerequis verifies

| Outil | Role | Verification |
|-------|------|--------------|
| Rust (stable, >= 1.78 conseille) | Compiler les services et `seed_sensor` | `rustc --version` |
| `protoc` | Generation gRPC | `protoc --version` |
| `k6` | Charge REST | `k6 version` |
| `ghz` | Charge gRPC | `ghz --version` |
| `curl` | Sante REST dans les scripts | `curl --version` |
| `python3` | Rapport `make report` | `python3 --version` |

Les versions recentes de **ghz** utilisent `--insecure` pour le plaintext (remplace l'ancien `--plaintext`). Les scripts du depot sont alignes sur ce comportement.

## Etape 1 : demarrer les services

Dans la racine du depot :

```bash
make run
```

Ou dans deux terminaux :

```bash
cargo run -p rest-service
```

```bash
cargo run -p grpc-service
```

Ports par defaut : REST `http://127.0.0.1:8080`, gRPC `127.0.0.1:50051`.

Variables utiles si besoin : `REST_BASE_URL`, `GRPC_HOST` (formats `hote:port` ou `http://hote:port` pour les clients internes).

## Etape 2 : executer la suite de charge

Toujours a la racine :

```bash
make bench
```

Pour figer un suffixe de fichiers (comparaison entre machines) :

```bash
export BENCH_TIMESTAMP=20260101-exemple
make bench
```

Sorties :

- `benchmark/results/rest/<timestamp>-scenario-{a,b,c}.json`
- `benchmark/results/grpc/<timestamp>-scenario-{a,b}.json`
- `benchmark/results/grpc/<timestamp>-scenario-c-concurrency-<n>.json` pour **plusieurs** valeurs de `n` (10, 20, … jusqu'a la limite configuree). C'est attendu : le scenario C gRPC repete `ghz` par palier de concurrence.

Le bench gRPC obtient un capteur de reference via `cargo run -p grpc-service --bin seed_sensor` (appelle `CreateSensor`). Vous pouvez fournir un UUID existant avec `export SENSOR_ID=...` si vous gerez vous-meme le seed.

## Etape 3 : generer le rapport consolide

Avec au moins un jeu REST **et** un jeu gRPC partageant le meme `<timestamp>` dans les noms de fichiers :

```bash
make report
```

Fichier produit : `benchmark/results/report-latest.md` (ecrase a chaque execution).

## Etape 4 : controles rapides

- [ ] Les services repondent avant bench (`curl` sur `/sensors`, port gRPC ouvert).
- [ ] Des fichiers `*-scenario-*.json` existent sous `benchmark/results/rest` et `benchmark/results/grpc`.
- [ ] `make report` se termine sans erreur et le tableau gRPC liste les lignes `C-CONCURRENCY-*`.
- [ ] Optionnel : `cargo test --all --verbose` pour valider le depot hors charge.

## Depannage

- **k6 / erreur `__ITER`** : mettre a jour le depot (correctif dans `benchmark/scripts/rest-scenarios.js`).
- **ghz / flag plaintext** : utiliser une version alignee avec les scripts ou verifier `--insecure`.
- **`cargo run -p grpc-service` ambigu** : specifier `--bin grpc-service` ou utiliser le manifest avec `default-run` (voir `grpc-service/Cargo.toml`).
