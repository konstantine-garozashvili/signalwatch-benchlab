# Guide de contribution

Merci de contribuer au projet **SignalWatch BenchLab** !
Ce document decrit les regles et conventions a respecter pour maintenir un code de qualite professionnelle.

---

## Strategie de branches

```
main          <- branche stable, protegee (merge uniquement via PR approuvee)
develop       <- branche d'integration
feature/*     <- nouvelles fonctionnalites (ex: feature/rest-crud-sensors)
fix/*         <- corrections de bugs (ex: fix/grpc-connection-timeout)
benchmark/*   <- scripts et resultats de benchmark
docs/*        <- documentation uniquement
```

### Regles
- Ne jamais pousser directement sur `main`
- Toute modification passe par une **Pull Request**
- La PR doit etre approuvee avant le merge
- Les branches sont supprimees apres le merge

---

## Conventions de commits (Conventional Commits)

Nous suivons la specification [Conventional Commits](https://www.conventionalcommits.org/fr/).

### Format

```
<type>(<portee>): <description courte>

[corps optionnel]

[pied de page optionnel]
```

### Types autorises

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalite |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `style` | Formatage, pas de changement logique |
| `refactor` | Refactorisation sans ajout de fonctionnalite |
| `test` | Ajout ou modification de tests |
| `bench` | Scripts ou resultats de benchmark |
| `chore` | Maintenance, dependances, CI |
| `perf` | Amelioration de performance |

### Exemples

```bash
feat(rest-service): ajout endpoint POST /sensors
fix(grpc-service): correction timeout connexion
docs: mise a jour du README avec les prerequis
bench(k6): ajout scenario charge progressive
chore: mise a jour dependances Cargo.toml
```

---

## Processus de Pull Request

1. Creer une branche depuis `develop` :
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/ma-fonctionnalite
   ```

2. Developper et committer avec les conventions ci-dessus

3. Pousser la branche et ouvrir une PR vers `develop` :
   ```bash
   git push origin feature/ma-fonctionnalite
   ```

4. Remplir le template de PR

5. Attendre la revue de code et adresser les commentaires

6. Merge apres approbation

---

## Standards de code Rust

- Formatter avec `cargo fmt` avant chaque commit
- Verifier avec `cargo clippy -- -D warnings` (zero avertissement tolere)
- Tous les tests doivent passer : `cargo test`
- Documenter les fonctions publiques avec des commentaires `///`

---

## Lancer les verifications localement

```bash
# Formatage
cargo fmt --all

# Linting
cargo clippy --all-targets --all-features -- -D warnings

# Tests
cargo test --all

# Build complet
cargo build --release
```

---

## Code de conduite

Ce projet respecte un environnement de travail respectueux et professionnel.
Toute forme de harcelement ou de comportement inapproprie sera signalee.
