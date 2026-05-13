# Plan de veille — REST vs gRPC pour SignalWatch

## Contexte et objectif

Ce plan de veille encadre la mission de conseil technique réalisée pour **SignalWatch**, startup IoT évaluant les protocoles de communication inter-services pour sa plateforme de monitoring industriel (10 000 événements/min, capteurs température/pression/vibration).

**Livrable cible :** recommandation protocolaire argumentée (REST vs gRPC) appuyée sur :
1. Une veille technologique et réglementaire multi-sources
2. Un benchmark empirique reproductible (Rust / Axum / Tonic)
3. Une analyse éco-conception (empreinte réseau, CPU/RAM)

---

## 1. Répartition thématique (Qui recherche quoi)

| Membre | Thème principal | Sous-thèmes |
|--------|----------------|-------------|
| **Konstantine G.** (Tech Lead) | Implémentation services + benchmark | Architecture Rust (Axum/Tonic), scripts k6/ghz, résultats bruts |
| **Membre 2** (Backend) | Protocoles de communication | REST/HTTP, gRPC/HTTP2, GraphQL, Protocol Buffers |
| **Membre 3** (QA/PM) | Réglementation + éco-conception | RGPD, RGESN, Green IT, CNIL IoT |
| **Membre 4** (Veille) | Message brokers + protocoles IoT émergents | Kafka, RabbitMQ, MQTT, CoAP, benchmarks littérature |

---

## 2. Sources par thème (minimum 3 par membre)

### Konstantine G. — Implémentation et benchmark

| Source | Type | Pertinence |
|--------|------|-----------|
| [gRPC official documentation](https://grpc.io/docs/) | Documentation officielle | Spécifications protocole, streaming, load balancing |
| [Tonic (Rust gRPC)](https://github.com/hyperium/tonic) | Documentation framework | Implémentation gRPC en Rust, meilleures pratiques |
| [Axum web framework](https://docs.rs/axum/latest/axum/) | Documentation framework | REST avec Tokio/Rust |
| [k6 documentation](https://k6.io/docs/) | Documentation outil | Métriques k6, export JSON, scenarios de charge |
| [ghz gRPC benchmarking tool](https://ghz.sh/) | Documentation outil | Benchmarking gRPC, flags --insecure, format JSON |
| [Protocol Buffers Language Guide](https://protobuf.dev/programming-guides/proto3/) | Documentation officielle | Définition .proto, encodage binaire, field types |

### Membre 2 — Protocoles de communication

| Source | Type | Pertinence |
|--------|------|-----------|
| [HTTP/2 RFC 7540](https://www.rfc-editor.org/rfc/rfc7540) | RFC / Standard | Spécifications HTTP/2 : multiplexing, HPACK, streams |
| [REST API Design Rulebook — O'Reilly](https://www.oreilly.com/library/view/rest-api-design/9781449317904/) | Livre technique | Principes REST, HATEOAS, meilleures pratiques |
| [Google Cloud Architecture Center — gRPC vs REST](https://cloud.google.com/blog/products/api-management/understanding-grpc-openapi-and-rest-and-when-to-use-them) | Blog technique référence | Cas d'usage comparés, recommandations Google |
| [GraphQL official documentation](https://graphql.org/learn/) | Documentation officielle | Cas d'usage GraphQL, introspection, over-fetching |
| [Martin Fowler — Microservices](https://martinfowler.com/articles/microservices.html) | Article académique référence | Architecture microservices, communication inter-services |
| [Benchmarking REST vs gRPC — Medium/Towards Data Science](https://medium.com/swlh/grpc-vs-rest-performance-simplified-7558f5f5e57a) | Article technique | Benchmark publié REST vs gRPC, données de référence |

### Membre 3 — Réglementation et éco-conception

| Source | Type | Pertinence |
|--------|------|-----------|
| [CNIL — RGPD et données IoT](https://www.cnil.fr/fr/iot-internet-des-objets) | Documentation officielle CNIL | Données personnelles IoT, obligations légales |
| [RGPD — Règlement (UE) 2016/679](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX%3A32016R0679) | Texte législatif | Base légale, durée de conservation, droits des personnes |
| [RGESN — Référentiel Général d'Écoconception des Services Numériques](https://ecoresponsable.numerique.gouv.fr/publications/referentiel-general-ecoconception/) | Référentiel gouvernemental | Critères éco-conception numérique, bonnes pratiques |
| [Green IT — Empreinte numérique](https://www.greenit.fr/empreinte-environnementale-du-numerique-mondial/) | Rapport de référence | Empreinte des infrastructures numériques |
| [ENISA — IoT Security Guidelines](https://www.enisa.europa.eu/publications/guidelines-for-securing-the-internet-of-things) | Documentation agence UE | Sécurité IoT, données industrielles, recommandations |
| [CNIL — Guide pratique de la durée de conservation](https://www.cnil.fr/fr/les-durees-de-conservation-des-donnees) | Guide pratique CNIL | Durées légales, données industrielles, archivage |

### Membre 4 — Message brokers et protocoles IoT émergents

| Source | Type | Pertinence |
|--------|------|-----------|
| [Apache Kafka documentation](https://kafka.apache.org/documentation/) | Documentation officielle | Architecture publish/subscribe, cas d'usage haute volumétrie |
| [RabbitMQ documentation](https://www.rabbitmq.com/documentation.html) | Documentation officielle | AMQP, routing, queues, cas d'usage IoT |
| [MQTT specification OASIS](https://mqtt.org/mqtt-specification/) | Standard OASIS | Protocole léger publish/subscribe pour IoT contraint |
| [CoAP RFC 7252](https://www.rfc-editor.org/rfc/rfc7252) | RFC | Protocole IoT contraint (UDP), cas d'usage capteurs |
| [Confluent — Kafka vs RabbitMQ](https://www.confluent.io/learn/kafka-vs-rabbitmq/) | Article technique | Comparatif message brokers, critères de choix |
| [IEEE — IoT Communication Protocols Survey](https://ieeexplore.ieee.org/document/8421938) | Article académique | Survey protocoles IoT, performance comparative |

---

## 3. Critères de fiabilité des sources

Les sources ont été validées selon les critères suivants :

| Critère | Description |
|---------|-------------|
| **Autorité** | Sources officielles (RFC, CNIL, gouvernementales) ou éditeurs reconnus (O'Reilly, IEEE) |
| **Actualité** | Sources publiées ou mises à jour après 2022 (protocoles évoluent rapidement) |
| **Reproductibilité** | Benchmarks avec méthodologie publiée, outils et versions documentés |
| **Indépendance** | Préférence pour sources académiques et open source vs documentations vendeurs uniquement |
| **Recoupement** | Tout chiffre de performance issu de la littérature recoupé avec au moins 2 sources |

---

## 4. Planning de la semaine (jour par jour)

| Jour | Activité | Membres | Livrable journalier |
|------|----------|---------|---------------------|
| **Lundi** | Cadrage + setup environnement | Tous | Repo initialisé, services compilables, proto défini |
| **Mardi** | Implémentation services + première veille protocolaire | K.G. + Membre 2 | CRUD fonctionnel REST + gRPC, sources protocolaires collectées |
| **Mercredi** | Scripts benchmark + veille réglementaire | K.G. + Membre 3 | Scénarios A/B/C fonctionnels, analyse RGPD rédigée |
| **Jeudi** | Exécution benchmarks + veille message brokers | K.G. + Membre 4 | JSON résultats dans `/benchmark/results`, sections Kafka/MQTT rédigées |
| **Vendredi matin** | Rapport + présentation | Tous | rapport-veille.pdf + presentation.pdf consolidés |
| **Vendredi après-midi** | Revue finale + dépôt GitHub | Tech Lead | Repo complet, README validé, tag de release |

---

## 5. Format de restitution interne

### Rythme de synchronisation
- **Point quotidien** (15 min, en début de journée) : avancement, blocages, ajustements
- **Document partagé** (Google Docs ou Notion) : notes de veille centralisées par thème
- **Canal Slack dédié** (`#benchlab`) : partage de sources, questions rapides

### Structure du document partagé
```
/BenchLab-Notes
  ├── veille-protocoles.md       # Notes Membre 2 (REST/gRPC/GraphQL)
  ├── veille-reglementation.md   # Notes Membre 3 (RGPD/éco)
  ├── veille-brokers.md          # Notes Membre 4 (Kafka/MQTT)
  └── decisions-techniques.md    # Décisions Tech Lead avec justification
```

### Critère de validation interne
Chaque section du rapport doit être relue par **au moins un autre membre** avant inclusion. Les données chiffrées issues de la littérature doivent mentionner leur source dans le document partagé.

---

## 6. RACI — Matrice de responsabilités

### Livrables

| Livrable | Responsible | Accountable | Consulted | Informed |
|----------|-------------|-------------|-----------|----------|
| Service REST (Axum) | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Service gRPC (Tonic) | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Scripts benchmark (k6/ghz) | Konstantine G. | Konstantine G. | Membre 3 | Tous |
| Résultats bruts JSON | Konstantine G. | Konstantine G. | Membre 3 | Tous |
| Rapport de veille — Introduction & méthodo | Membre 3 (PM) | Konstantine G. | Tous | — |
| Rapport — Panorama protocoles | Membre 2 | Konstantine G. | Membre 4 | Tous |
| Rapport — Résultats benchmark | Konstantine G. | Konstantine G. | Membre 2 | Tous |
| Rapport — Analyse éco-conception | Membre 3 | Konstantine G. | Membre 2 | Tous |
| Rapport — Analyse réglementaire (RGPD) | Membre 3 | Membre 3 | Konstantine G. | Tous |
| Rapport — Recommandation finale | Konstantine G. | Konstantine G. | Tous | CTO SignalWatch |
| Support de présentation | Membre 2 + Membre 4 | Konstantine G. | Tous | — |
| README + docs techniques | Konstantine G. | Konstantine G. | Membre 2 | Tous |

### Légende RACI
- **R** — Responsible : réalise la tâche
- **A** — Accountable : valide et porte la responsabilité finale
- **C** — Consulted : consulté avant décision, échange bilatéral
- **I** — Informed : informé du résultat, communication unilatérale

---

## 7. Indicateurs de qualité du projet

| Indicateur | Cible | Statut |
|------------|-------|--------|
| Services compilant sans warning | 0 warning clippy | ✅ |
| Scénarios benchmark A/B/C | 3 scénarios documentés et exécutés | ✅ |
| Résultats JSON versionnés | Présents dans `/benchmark/results/` | ✅ |
| Rapport de veille (pages) | 8-10 pages | ✅ |
| Support de présentation (slides) | 10 slides max | ✅ |
| Sources par membre | ≥ 3 sources par thème | ✅ |
| Reproductibilité (`make bench`) | En une commande | ✅ |
| Analyse éco-conception | Taille payload + extrapolation | ✅ |
| Analyse RGPD | Données personnelles IoT + obligations | ✅ |
