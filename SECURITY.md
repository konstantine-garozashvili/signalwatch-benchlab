# Politique de securite

## Versions supportees

| Version | Supportee |
|---------|-----------|
| main    | Oui       |
| develop | Oui       |
| autres  | Non       |

---

## Signaler une vulnerabilite

Si vous decouvrez une vulnerabilite de securite dans ce projet, merci de **ne pas ouvrir une issue publique**.

### Procedure

1. Contactez directement le mainteneur via les **GitHub Security Advisories** :
   - Allez dans `Security` > `Advisories` > `Report a vulnerability`

2. Incluez dans votre rapport :
   - Une description detaillee de la vulnerabilite
   - Les etapes pour la reproduire
   - L'impact potentiel
   - Une suggestion de correction si possible

3. Vous recevrez une reponse sous **48 heures**.

4. Une fois la vulnerabilite corrigee, elle sera divulguee publiquement dans les notes de version.

---

## Perimetre de securite

Ce projet est un benchmark academique. Les points d'attention principaux sont :

- Injection dans les parametres des capteurs (SQL, format)
- Exposition involontaire de donnees sensibles dans les logs
- Dependances Rust avec des vulnerabilites connues (surveiller avec `cargo audit`)

---

## Audit des dependances

```bash
# Installer cargo-audit
cargo install cargo-audit

# Lancer l'audit
cargo audit
```

L'audit des dependances est execute automatiquement dans la CI (GitHub Actions).
