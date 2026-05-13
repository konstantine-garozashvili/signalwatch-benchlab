# Notes de présentation — SignalWatch BenchLab
## REST vs gRPC pour l'IoT industriel

> **Usage :** Ce document contient le texte à DIRE pendant la présentation, pas simplement ce qui est affiché sur les slides.
> Ton cible : professionnel mais accessible, comme si on s'adressait à un CTO et son équipe technique.
> Durée totale estimée : 25–30 minutes.

---

## Slide 1 — Contexte SignalWatch et problématique

**Durée suggérée :** 3 minutes

**Ce que vous voyez :** Présentation de SignalWatch — startup IoT fictive, capteurs industriels (température, pression, vibration), 10 000 événements par minute, mission de recommander un protocole de communication inter-services.

**Ce que vous dites :**

Bonjour à tous. Permettez-moi de vous présenter SignalWatch — une startup IoT industrielle fictive, créée dans le cadre de ce projet école à La Plateforme. L'idée est simple : on surveille des capteurs industriels — température, pression, vibration — dans des environnements de production réels. Des usines, des entrepôts, des sites énergétiques.

Maintenant, ce qui rend ce projet intéressant d'un point de vue technique, c'est le volume. On parle de 10 000 événements par minute, en continu, 24 heures sur 24, 365 jours par an. C'est pas une API qu'on appelle de temps en temps depuis une interface web — c'est un flux permanent de données critiques.

Dans ce contexte, la question qui nous a été posée est : **quel protocole de communication inter-services choisir ?** Et c'est pas une question anodine. Le choix du protocole a des implications directes sur les performances, la maintenabilité du code, la consommation réseau, et à terme, le coût opérationnel de la plateforme.

Deux candidats principaux s'affrontent : **REST sur HTTP/1.1**, la valeur sûre que tout le monde connaît, et **gRPC sur HTTP/2**, le challenger performant mais plus complexe à mettre en œuvre.

Notre approche a été empirique : on a implémenté les deux en Rust — Axum pour REST, Tonic pour gRPC — et on les a soumis à des benchmarks rigoureux avec des outils spécialisés. k6 pour la charge REST, ghz pour gRPC. L'environnement : macOS local avec loopback réseau, ce qui nous permet de mesurer les protocoles eux-mêmes, sans le bruit du réseau physique.

Tout au long de cette présentation, on va vous présenter les résultats, l'analyse éco-conception, les contraintes réglementaires, et finalement notre recommandation. Et je vous annonce la couleur : la réponse n'est pas binaire.

**Points clés à souligner :**
- SignalWatch est un cas d'usage IoT haute fréquence, pas une API classique
- 10 000 événements/min = contrainte de débit, pas juste de latence
- Approche empirique : implémentation réelle + benchmark outillé
- La réponse finale sera nuancée (approche hybride)

**Questions possibles :**
- Q: Pourquoi Rust et pas Go ou Java, qui sont plus courants dans ce contexte ?
  R: Rust offre des performances natives sans garbage collector, ce qui évite les pauses GC dans les mesures de latence. Pour un benchmark propre, c'est un choix délibéré — on veut mesurer le protocole, pas le runtime. De plus, Rust est de plus en plus adopté dans l'IoT industriel pour ses garanties de sécurité mémoire.

- Q: Est-ce que 10 000 événements par minute c'est réaliste pour une startup ?
  R: Oui, tout à fait. Un seul site industriel avec 200 capteurs qui émettent toutes les secondes donne déjà 12 000 événements par minute. SignalWatch cible précisément ce segment — des déploiements mid-scale avant de passer à des architectures plus distribuées.

- Q: Pourquoi comparer seulement REST et gRPC ? Il y a d'autres options.
  R: Bonne question — et on va y répondre justement dans la slide suivante où on fait un panorama des protocoles disponibles, dont GraphQL et les message brokers. Mais le coeur de la comparaison reste REST vs gRPC parce que ce sont les deux candidats les plus pertinents pour de la communication synchrone inter-services.

---

## Slide 2 — Panorama protocoles — REST / HTTP

**Durée suggérée :** 2 minutes 30

**Ce que vous voyez :** Description de REST/HTTP — architecture, caractéristiques, cas d'usage, avantages et inconvénients.

**Ce que vous dites :**

Avant de plonger dans les chiffres, il faut qu'on soit tous alignés sur ce qu'on compare. Commençons par REST.

REST — Representational State Transfer — c'est pas vraiment un protocole, c'est un style architectural défini par Roy Fielding en 2000. Il repose sur HTTP, avec des verbes standardisés : GET pour lire, POST pour créer, PUT ou PATCH pour modifier, DELETE pour supprimer. Les ressources sont identifiées par des URLs, et les échanges se font généralement en JSON.

Ce qui fait la force de REST, c'est son **universalité**. Tout le monde sait faire du REST. Tous les langages ont des clients HTTP. Tous les outils de monitoring comprennent HTTP. Les proxys, les load balancers, les CDN — tout ça est natif avec REST. Et le debugging est trivial : vous ouvrez votre navigateur ou Postman, vous faites une requête, vous voyez ce qui se passe.

L'autre avantage, c'est la **lisibilité humaine**. Le JSON, c'est verbeux, c'est pas optimal en termes de taille, mais ça se lit à l'oeil nu. Pour du debugging en production, c'est précieux.

Maintenant, les limites. HTTP/1.1 n'a pas de multiplexage — chaque requête ouvre une connexion ou attend sa place dans une connexion persistante. À haute fréquence, ça crée des goulots d'étranglement. Le JSON lui-même est lourd par rapport à un format binaire — on va quantifier ça précisément dans la slide éco-conception. Et REST n'a pas de contrat fort entre le client et le serveur — si l'API change, vous le découvrez parfois... au runtime.

Pour SignalWatch, REST reste néanmoins le point de départ naturel : c'est ce que les intégrateurs connaissent, c'est ce que les outils de supervision attendent, et pour des volumes modérés, ça tient parfaitement la charge.

**Points clés à souligner :**
- REST = style architectural, pas un protocole à proprement parler
- Universalité et interopérabilité maximales
- JSON lisible mais verbeux
- Pas de contrat fort client-serveur (contrairement à Protobuf)
- HTTP/1.1 : pas de multiplexage natif

**Questions possibles :**
- Q: HTTP/2 existe depuis 2015 — pourquoi ne pas faire du REST sur HTTP/2 ?
  R: C'est une excellente remarque. On peut effectivement faire du REST sur HTTP/2, et ça améliore le multiplexage. Mais dans la pratique, la plupart des stacks REST en production utilisent encore HTTP/1.1 avec keep-alive. Et les avantages d'HTTP/2 sont mieux exploités par gRPC qui en utilise les fonctionnalités de streaming nativement. Notre benchmark mesure les configurations les plus courantes.

- Q: Vous parlez de "contrat fort" — c'est quoi exactement ?
  R: Avec REST en JSON, le serveur peut changer le nom d'un champ, en ajouter un, en supprimer un — le client ne le sait pas avant l'exécution. Avec gRPC et Protobuf, le contrat est défini dans un fichier `.proto` : si le serveur change l'interface, le code client ne compile plus. C'est un filet de sécurité fort, surtout dans des équipes distribuées.

- Q: Est-ce que REST peut gérer du streaming ?
  R: Oui, via Server-Sent Events ou WebSockets, mais c'est pas natif dans REST — ça sort du modèle request-response classique. gRPC a le streaming bidirectionnel intégré dans son modèle de base, ce qui est un avantage net pour de la télémétrie continue.

---

## Slide 3 — Panorama protocoles — gRPC / HTTP2 + GraphQL + Message Brokers

**Durée suggérée :** 2 minutes 30

**Ce que vous voyez :** Description de gRPC — Protobuf, HTTP/2, streaming. Présentation rapide de GraphQL et des message brokers (MQTT, Kafka) comme alternatives écartées.

**Ce que vous dites :**

Passons maintenant au challenger : gRPC. C'est un framework RPC — Remote Procedure Call — développé par Google et open-sourcé en 2015. L'idée : au lieu d'appeler une URL, vous appelez une **fonction** sur un service distant. Et ça change tout dans la façon dont on structure le code.

gRPC repose sur deux piliers. Le premier : **Protobuf** — Protocol Buffers — un format de sérialisation binaire. Vous définissez vos messages et vos services dans un fichier `.proto`, et le compilateur génère le code client et serveur dans le langage de votre choix. Le résultat est beaucoup plus compact qu'un JSON équivalent — on va mesurer ça précisément. Le second pilier : **HTTP/2**, avec multiplexage, compression des headers HPACK, et support natif du streaming bidirectionnel.

Pour SignalWatch, le streaming gRPC est particulièrement intéressant : un capteur peut ouvrir une stream persistante avec le serveur et envoyer des mesures en continu, sans overhead de connexion à chaque événement.

Mais il faut être honnête sur les limites. gRPC est **nettement plus complexe** à mettre en place. Le debugging n'est pas trivial — vous ne pouvez pas juste "curl" une API gRPC. Il faut des outils spécifiques comme grpcurl ou Postman avec support gRPC. Et l'écosystème, bien que mature, est moins universel que REST.

Deux autres options méritent d'être mentionnées rapidement. **GraphQL** — excellente option pour des APIs client-facing avec des besoins de requêtage flexibles, mais ça n'apporte pas de bénéfice pour de la communication machine-à-machine à haute fréquence. Et les **message brokers** — MQTT ou Kafka — sont parfaits pour de l'asynchrone et du pub/sub, mais ça représente une rupture architecturale bien plus importante. Ce sont des options pour une évolution future de SignalWatch, pas pour la v1.

**Points clés à souligner :**
- gRPC = appel de fonction distante, pas de ressource URL
- Protobuf : contrat fort, format binaire compact, génération de code
- HTTP/2 : multiplexage + streaming bidirectionnel natif
- gRPC plus performant mais plus complexe à opérer
- GraphQL et message brokers : écartés pour la communication synchrone inter-services

**Questions possibles :**
- Q: Pourquoi pas MQTT directement pour de l'IoT ? C'est le standard du secteur.
  R: MQTT est effectivement le standard pour la communication capteur-vers-gateway dans l'IoT basse consommation. Mais ici on parle de communication inter-services côté backend — entre le service d'ingestion et le service de traitement par exemple. MQTT serait pertinent pour la couche device-to-cloud, mais pour le backend inter-services, gRPC ou REST sont plus appropriés.

- Q: Est-ce que gRPC fonctionne dans un navigateur ?
  R: Pas nativement. Il faut gRPC-Web, une adaptation qui utilise un proxy intermédiaire. C'est une vraie limite pour des APIs exposées à des frontends web. C'est d'ailleurs une des raisons pour lesquelles l'approche hybride qu'on recommandera garde REST pour certains usages.

- Q: Vous avez implémenté le streaming gRPC dans votre benchmark ?
  R: Le benchmark couvre principalement le mode unary — une requête, une réponse — pour avoir une comparaison directe avec REST. Le streaming gRPC est mentionné comme perspective d'évolution, et c'est là où les gains seraient probablement encore plus significatifs pour SignalWatch.

---

## Slide 4 — Résultats benchmark Scénario A (Lecture unitaire)

**Durée suggérée :** 3 minutes

**Ce que vous voyez :** Résultats du Scénario A — GET d'un capteur individuel. REST : 1000 requêtes, 10 VUs concurrents. gRPC : configuration équivalente. Métriques p50, p95, p99, throughput.

**Ce que vous dites :**

Entrons dans le vif du sujet — les données. Le Scénario A est le cas le plus simple : lire la mesure d'un capteur individuel. C'est le pattern de base, celui qui constitue l'essentiel du trafic en lecture dans une plateforme de monitoring.

Pour REST, on a lancé k6 avec 1000 requêtes et 10 VUs — Virtual Users — concurrents. Résultat : **p50 à 0,15 ms**, p95 à 0,34 ms, et un throughput de **42 030 requêtes par seconde**. Zéro erreur. Ces chiffres sont remarquables.

Pour gRPC, avec ghz dans une configuration équivalente : **p50 à 0,48 ms**, p95 à 0,78 ms, p99 à 1,11 ms, throughput de **16 113 requêtes par seconde**. Également zéro erreur.

Premier constat, et c'est celui qui surprend le plus les gens : **REST est plus rapide que gRPC sur ce scénario.** Presque trois fois plus de throughput, et latence médiane trois fois plus faible. Comment expliquer ça ?

Deux facteurs principaux. D'abord, l'**overhead de connexion** : gRPC maintient des connexions HTTP/2 avec négociation initiale plus complexe. Sur des requêtes courtes et nombreuses en loopback, cet overhead devient proportionnellement significatif. Ensuite, Axum et Tonic ne sont pas équivalents en termes de maturité d'optimisation — Axum est extrêmement bien optimisé pour les requêtes HTTP simples.

Deuxième point important : l'**environnement de test**. On est en loopback réseau sur macOS. La latence réseau est quasi-nulle. Dans un vrai déploiement distribué, avec 5 ou 10 millisecondes de latence réseau, les cartes sont redistribuées — les différences de protocole deviennent proportionnellement moins visibles, et les avantages du multiplexage HTTP/2 s'expriment mieux.

Retenez que REST excelle sur les lectures unitaires à faible latence réseau.

**Points clés à souligner :**
- REST bat gRPC sur la latence et le throughput en Scénario A
- p50 REST : 0,15 ms vs gRPC : 0,48 ms — facteur 3x
- Throughput REST : 42 030 req/s vs gRPC : 16 113 req/s
- L'avantage REST s'explique par le contexte loopback et la maturité d'Axum
- Ces résultats ne se généralisent pas nécessairement à un réseau distribué

**Questions possibles :**
- Q: Ces latences sont irréellement faibles — 0,15 ms pour une requête réseau ?
  R: Oui, c'est très bas, et c'est précisément parce qu'on est en loopback réseau — les paquets ne quittent jamais la machine. C'est un choix délibéré pour isoler la variable "protocole" de la variable "réseau physique". En production avec un réseau inter-datacenter, les latences seraient de l'ordre de 1 à 10 ms, mais les différences relatives entre REST et gRPC resteraient comparables.

- Q: Pourquoi k6 ne fournit pas le p99 comme ghz ?
  R: C'est une limite du format de sortie JSON summary de k6 — il exporte p90 et p95 par défaut, mais pas p99. On aurait pu le configurer avec des options custom, mais on a choisi de rester avec les exports par défaut pour la reproductibilité. C'est un point de vigilance pour les benchmarks futurs.

- Q: 42 000 req/s REST c'est largement au-dessus des 10 000 événements/min de SignalWatch — est-ce que ça veut dire que REST suffit largement ?
  R: En termes de débit brut, oui — 42 000 req/s pour une cible de 167 req/s (10 000/min) donne une marge de sécurité énorme. Mais la question n'est pas seulement le throughput de pic — c'est aussi la latence sous charge soutenue, la consommation réseau sur la durée, et la capacité à gérer des pics imprévus. C'est ce qu'on explore dans le Scénario C.

---

## Slide 5 — Résultats benchmark Scénario B (Écriture)

**Durée suggérée :** 2 minutes 30

**Ce que vous voyez :** Résultats du Scénario B — écriture d'une mesure capteur (POST REST / write unary gRPC). REST : 500 requêtes, 5 VUs. gRPC : configuration équivalente. Métriques comparées.

**Ce que vous dites :**

Le Scénario B inverse la perspective : on s'intéresse à l'écriture. C'est le flux le plus critique pour SignalWatch — les capteurs envoient leurs mesures vers la plateforme en permanence. Si l'écriture est le goulot d'étranglement, c'est là que tout s'effondre.

Avec REST, on a fait 500 requêtes POST avec 5 VUs concurrents. Résultat : **p50 à 0,14 ms**, p95 à 0,26 ms, throughput de **24 575 requêtes par seconde**. Toujours zéro erreur.

Pour gRPC, **p50 à 0,22 ms**, p95 à 0,36 ms, p99 à 0,46 ms, throughput de **16 921 req/s**. Zéro erreur également.

Le pattern est cohérent avec le Scénario A : REST reste plus rapide sur ce type de charge. Mais regardons les chiffres avec plus de nuance. L'**écart se réduit** par rapport au Scénario A. REST a un avantage de facteur 1,45 sur le throughput ici — contre un facteur 2,6 sur le Scénario A. Et sur la latence médiane, l'écart est de 0,08 ms — quasi-imperceptible en pratique.

Ce que ça nous dit : gRPC est plus compétitif sur l'écriture que sur la lecture, dans notre configuration. Pourquoi ? L'opération d'écriture implique un traitement légèrement plus lourd côté serveur — validation, stockage — et le protocole lui-même devient moins déterminant dans le temps total de traitement.

Maintenant, 24 575 req/s pour REST et 16 921 req/s pour gRPC, face à un besoin de 167 événements par seconde — les deux sont largement surdimensionnés. La vraie question, c'est : comment ça se comporte quand on monte vraiment en charge ?

**Points clés à souligner :**
- REST encore plus rapide sur l'écriture, mais l'écart se réduit
- p50 REST 0,14 ms vs gRPC 0,22 ms — facteur 1,6x (vs 3x en Scénario A)
- Throughput REST 24 575 vs gRPC 16 921 — facteur 1,45x
- Les deux protocoles largement au-dessus des besoins de SignalWatch en mode nominal
- gRPC devient relativement plus compétitif quand le traitement serveur est plus lourd

**Questions possibles :**
- Q: Est-ce que le body du POST en REST était identique au message Protobuf en gRPC ?
  R: Le contenu informatif était équivalent — identifiant capteur, timestamp, valeur, unité. Mais le format diffère : en REST on envoie du JSON dans le body HTTP, en gRPC on envoie un message Protobuf binaire. C'est précisément cette différence de format qu'on analyse dans la slide éco-conception pour calculer le ratio de données transférées.

- Q: Avec 5 VUs seulement pour le Scénario B, est-ce représentatif ?
  R: 5 VUs avec 500 requêtes donne un test de charge légère, représentatif d'un flux normal. On a délibérément gardé un nombre de VUs bas pour mesurer les performances unitaires sans saturation. Le Scénario C répond à votre question — il teste la montée en charge jusqu'à 100 VUs.

- Q: Les capteurs IoT envoient vraiment des requêtes HTTP individuelles ?
  R: En architecture microservices backend, oui — les services communiquent typiquement requête par requête. À la couche device, un gateway agrège souvent les données avant de les envoyer au backend. Dans notre architecture, on modélise la communication entre le service d'ingestion et le service de traitement, pas entre le capteur physique et le gateway.

---

## Slide 6 — Résultats benchmark Scénario C (Montée en charge progressive)

**Durée suggérée :** 3 minutes

**Ce que vous voyez :** Résultats du Scénario C — ramp-up de 10 à 100 VUs concurrents. REST : agrégat sur la montée. gRPC : métriques à 10, 50 et 100 VUs. Mise en évidence de la dégradation gRPC à haute concurrence.

**Ce que vous dites :**

C'est la slide la plus importante du benchmark. Le Scénario C, c'est le test de vérité : on ne teste plus les performances nominales, on teste la **résilience sous charge**. On part de 10 utilisateurs concurrents et on monte progressivement jusqu'à 100.

Côté REST avec k6 : sur l'ensemble de la montée en charge, p50 à **0,43 ms**, p95 à **1,31 ms**, throughput agrégé de **70 297 req/s**. Zéro erreur. Ces chiffres restent très solides même à 100 VUs.

Côté gRPC avec ghz, les chiffres racontent une histoire différente. À 10 VUs concurrents : p50 à **0,44 ms**, p99 à **0,80 ms** — comparable à REST, rien d'alarmant. On monte à 50 VUs : p50 passe à **2,44 ms**, p99 à **3,15 ms**. À 100 VUs : p50 à **4,53 ms**, p99 à **8,12 ms**, throughput de **15 205 req/s**.

Voilà le signal le plus important de notre benchmark. **gRPC dégrade significativement avec la concurrence** dans notre environnement de test. Entre 10 et 100 VUs, la latence médiane gRPC est multipliée par 10. REST, lui, reste stable.

Comment expliquer ça ? Dans notre configuration locale avec Tonic, la gestion du pool de connexions HTTP/2 sous forte concurrence génère de la contention. Les connexions HTTP/2 sont multiplexées, mais ça ne signifie pas illimité — la gestion des streams concurrents a un coût. En production avec une infrastructure adaptée — load balancer, connexions persistantes gérées correctement — ce comportement serait probablement différent.

C'est là que notre benchmark atteint ses limites, et on va en parler en conclusion. Mais ce qu'on peut affirmer avec certitude : **dans notre environnement, REST est plus prédictible sous charge que gRPC**.

**Points clés à souligner :**
- Scénario C = test de résilience, le plus critique pour SignalWatch
- REST stable : p50=0,43 ms et p95=1,31 ms même à haute concurrence
- gRPC dégrade : p50 passe de 0,44 ms (10 VUs) à 4,53 ms (100 VUs) — facteur 10x
- Cette dégradation gRPC est probablement liée à la gestion des connexions HTTP/2 en local
- REST plus prédictible sous charge dans notre environnement

**Questions possibles :**
- Q: La dégradation gRPC à 100 VUs n'est-elle pas juste un problème de configuration ?
  R: Très probablement, oui — en partie. Une configuration optimale du pool de connexions HTTP/2, un vrai load balancer, et des instances multiples changeraient les chiffres. Mais c'est précisément le point : REST est plus tolérant aux configurations sous-optimales. gRPC demande une maîtrise opérationnelle plus fine pour exprimer son potentiel. C'est un critère de choix, pas une disqualification.

- Q: Le throughput gRPC de 15 205 req/s à 100 VUs — c'est pas si mal non ?
  R: En termes absolus, c'est correct. Mais regardez la latence : p99 à 8 ms, ça commence à être perceptible dans un pipeline de traitement en temps réel. Et surtout, la tendance est inquiétante — si on monte à 200 VUs, où est-on ? REST montre une courbe de dégradation beaucoup plus lisse.

- Q: Vous avez testé au-delà de 100 VUs ?
  R: Non, on a plafonné à 100 VUs pour rester dans des paramètres réalistes pour SignalWatch. 100 utilisateurs concurrents en loopback représente déjà une charge bien supérieure au trafic nominal de la plateforme. Aller au-delà aurait mis en évidence les limites de la machine de test plus que celles du protocole.

---

## Slide 7 — Analyse éco-conception

**Durée suggérée :** 3 minutes

**Ce que vous voyez :** Comparaison de la consommation réseau REST vs gRPC. Données mesurées : 410 octets/requête (REST) vs 153 octets/requête (gRPC). Projection annuelle à l'échelle SignalWatch : REST=2 155 Go/an, gRPC=804 Go/an, économie=1 351 Go/an.

**Ce que vous dites :**

L'éco-conception, c'est un critère qui monte en importance dans les décisions d'architecture — pas seulement pour des raisons éthiques, mais aussi économiques. Moins de données transférées, c'est moins de bande passante facturée, moins d'énergie consommée par les équipements réseau, et une empreinte carbone réduite.

On a mesuré la consommation réseau directement depuis les outils de benchmark. Pour REST, k6 remonte les métriques `data_received` et `http_reqs` — ça donne **410 octets par requête** en moyenne. Ça se décompose ainsi : environ 150 octets de headers HTTP/1.1, et environ 260 octets de body JSON pour un message capteur typique.

Pour gRPC, on a une estimation calculée — ghz ne remonte pas directement les octets par requête. On arrive à **153 octets par requête** : environ 123 octets de payload Protobuf binaire, et environ 30 octets de headers HPACK compressés HTTP/2.

Le ratio est de **2,7x** en faveur de gRPC. Pour une seule requête, c'est 257 octets d'économie — ça paraît négligeable. Mais à l'échelle de SignalWatch, ça devient très concret.

Faisons le calcul ensemble. 10 000 événements par minute × 60 minutes × 24 heures × 365 jours = 5,256 milliards de requêtes par an. Multipliez par 410 octets pour REST : **2 155 Go par an**. Par 153 octets pour gRPC : **804 Go par an**. L'économie : **1 351 Go par an** — soit environ 1,35 téraoctet.

Sur un hébergement cloud standard à 0,08€ le Go de sortie réseau, c'est environ **108 euros d'économie annuelle** uniquement sur la bande passante. C'est pas colossal à ce stade, mais ça s'additionne avec la croissance, et ça s'applique à chaque tier de l'architecture.

**Points clés à souligner :**
- REST : 410 octets/req (mesuré k6) = 150B headers + 260B JSON
- gRPC : 153 octets/req (estimé) = 123B Protobuf + 30B HPACK
- Ratio 2,7x en faveur de gRPC
- À l'échelle SignalWatch : 2 155 Go/an (REST) vs 804 Go/an (gRPC) — économie de 1,35 To/an
- L'éco-conception est aussi un argument économique, pas seulement éthique

**Questions possibles :**
- Q: Vous dites que les 153 octets pour gRPC sont une "estimation" — pourquoi pas une mesure directe ?
  R: ghz ne remonte pas les métriques réseau brutes de la même façon que k6. On a calculé la taille des messages Protobuf en les sérialisant manuellement depuis notre définition `.proto`, et on a estimé les headers HPACK sur la base de la spécification HTTP/2. C'est une approximation raisonnable, mais moins robuste que la mesure directe de k6 pour REST. Idéalement, on utiliserait Wireshark ou eBPF pour une mesure exacte.

- Q: Le chiffre de 108€/an d'économie — c'est vraiment significatif pour une startup ?
  R: À l'échelle d'un seul déploiement et de cette volumétrie, non. Mais c'est un ordre de grandeur qui se multiplie avec le nombre de clients, le nombre de tiers réseau, et la croissance des données. Et au-delà du coût direct, c'est aussi un argument commercial — les industriels sont de plus en plus sensibles à l'empreinte environnementale de leurs solutions.

- Q: Protobuf est vraiment 2,7x plus compact que JSON sur des données IoT ?
  R: Sur des structures simples avec des valeurs numériques — comme des mesures de capteurs — oui, le ratio est typiquement dans cette plage. JSON encode les nombres en ASCII (par exemple "temperature":23.5 = 16 caractères), là où Protobuf encode un float32 en 4 octets fixes. Sur des structures plus complexes avec beaucoup de chaînes de caractères, le ratio serait plus faible.

---

## Slide 8 — RGPD et réglementation IoT industriel

**Durée suggérée :** 2 minutes

**Ce que vous voyez :** Cadre réglementaire applicable à SignalWatch — RGPD (données personnelles possibles si capteurs liés à des opérateurs), NIS2 (cybersécurité infrastructures critiques), Cyber Resilience Act, considérations sectorielles.

**Ce que vous dites :**

La technique c'est une chose, mais aucune plateforme industrielle ne vit dans un vide réglementaire. Cette slide, c'est la réalité du terrain pour un CTO qui déploie SignalWatch en Europe.

Le **RGPD** est le premier cadre à considérer. À première vue, des capteurs industriels de température et pression — pas de données personnelles, pas de problème. Mais regardez de plus près : si les capteurs sont associés à des postes de travail ou à des opérateurs identifiés, si les données de vibration permettent d'inférer les rythmes de travail ou les présences — on rentre dans le périmètre du RGPD. Le principe de minimisation des données s'applique : ne collecter que ce qui est strictement nécessaire.

La directive **NIS2**, entrée en vigueur en 2024, est particulièrement pertinente pour l'IoT industriel. Elle couvre les "entités essentielles" dans des secteurs comme l'énergie, les transports, l'industrie manufacturière. Elle impose des exigences de sécurité renforcées, de traçabilité des incidents, et de notification obligatoire dans les 24 heures. Pour SignalWatch qui opère dans des usines ou des sites énergétiques, c'est une obligation potentielle, pas une option.

Le **Cyber Resilience Act** européen va plus loin : il imposera des exigences de sécurité dès la conception pour les produits connectés, avec des certifications obligatoires. Il entrera pleinement en vigueur progressivement jusqu'en 2027.

Concrètement, quel impact sur notre choix de protocole ? gRPC offre un avantage sur le chiffrement — TLS est pratiquement obligatoire et intégré nativement dans le modèle gRPC. REST peut très bien utiliser TLS, mais c'est moins "natif" dans certaines implémentations légères. Dans les deux cas, notre recommandation inclut TLS obligatoire, authentification mutuelle pour les services internes, et journalisation des accès.

**Points clés à souligner :**
- RGPD peut s'appliquer même à des données "techniques" si elles sont liées à des personnes
- NIS2 impose des exigences de cybersécurité aux opérateurs d'infrastructures critiques
- Cyber Resilience Act : sécurité by design pour les produits connectés
- gRPC facilite le TLS natif, mais REST avec TLS est tout aussi sécurisé si bien configuré
- La conformité réglementaire est un critère de choix architectural, pas une afterthought

**Questions possibles :**
- Q: NIS2 s'applique vraiment à une startup comme SignalWatch ?
  R: Ça dépend de la taille et des clients. NIS2 couvre directement les "entités essentielles" et "importantes" au-delà d'un certain seuil de taille. Mais une startup qui vend à des opérateurs d'infrastructures critiques doit se conformer aux exigences de ses clients, qui eux sont soumis à NIS2. En pratique, les exigences NIS2 se propagent dans la chaîne de valeur.

- Q: Le choix entre REST et gRPC a-t-il un impact sur la conformité RGPD ?
  R: Pas directement. La conformité RGPD dépend de ce qu'on collecte, comment on le stocke, et comment on le protège — pas du protocole de transport. Les deux protocoles peuvent être conformes RGPD avec une implémentation correcte. Ce qu'on peut noter : le format binaire Protobuf de gRPC est moins facilement lisible si intercepté, mais ça ne remplace pas le chiffrement.

- Q: Faut-il un DPO pour SignalWatch ?
  R: Si SignalWatch traite des données personnelles à grande échelle — ce qui est possible si les capteurs sont liés à des personnes — un DPO peut être obligatoire. C'est une question légale qui dépend de la nature exacte des données traitées et du volume. Notre recommandation : consulter un juriste RGPD dès la phase de product design.

---

## Slide 9 — Matrice de décision multicritères et recommandation

**Durée suggérée :** 4 minutes

**Ce que vous voyez :** Tableau de la matrice de décision avec critères pondérés, scores REST et gRPC sur chaque critère, scores finaux : REST 3,90/5, gRPC 3,85/5. Recommandation hybride.

**Ce que vous dites :**

On arrive au coeur de notre recommandation. Après tout ce qu'on a mesuré et analysé, il faut synthétiser. La matrice de décision multicritères, c'est notre outil pour rationaliser un choix qui serait autrement purement intuitif.

On a défini plusieurs critères, pondérés selon leur importance pour SignalWatch. Les voici avec leurs poids et les scores qu'on a attribués à chaque protocole.

Les **performances brutes** — poids important — données du benchmark : REST marque mieux sur la latence et la stabilité sous charge dans notre environnement. Les **performances à haute concurrence** — le Scénario C — même tendance. La **compacité des données** — l'éco-conception — gRPC gagne clairement avec son ratio 2,7x. La **facilité d'intégration et d'opération** — ecosystème, debugging, onboarding — REST gagne nettement. Le **contrat d'interface** — fiabilité du contrat client-serveur — gRPC gagne avec Protobuf. La **conformité et sécurité** — les deux sont équivalents avec TLS. La **scalabilité à long terme** — gRPC avec streaming a un avantage théorique.

Score final : **REST 3,90/5**, **gRPC 3,85/5**. Un écart de 0,05 point. Et c'est là que réside toute la subtilité de notre recommandation.

Avec un écart aussi faible, une recommandation binaire serait intellectuellement malhonnête. Ce qu'on recommande : une **approche hybride progressive**.

**Phase 1 — Maintenant** : démarrer en REST. L'écosystème est immédiat, le debugging est simple, l'onboarding des développeurs est rapide. Avec 42 000 req/s de capacité face à un besoin de 167 req/s, il y a une marge de sécurité confortable.

**Phase 2 — À 6-12 mois** : identifier les flux à haute fréquence et haute criticité — typiquement le flux d'ingestion des mesures de capteurs — et les migrer vers gRPC avec streaming bidirectionnel. C'est là que gRPC exprime son plein potentiel.

**Phase 3 — Long terme** : une architecture mixte mature, avec REST pour les APIs publiques et client-facing, gRPC pour les communications inter-services critiques.

**Points clés à souligner :**
- Scores très proches : REST 3,90 vs gRPC 3,85 — pas de gagnant absolu
- La recommandation n'est pas binaire mais hybride et progressive
- Phase 1 : REST pour démarrer vite et bien
- Phase 2 : gRPC pour les flux haute fréquence une fois la plateforme stabilisée
- L'approche hybride est la norme dans les architectures microservices matures

**Questions possibles :**
- Q: Comment éviter d'avoir une architecture trop complexe avec deux protocoles ?
  R: C'est un risque réel. La clé, c'est de ne pas migrer vers gRPC de manière opportuniste — il faut une règle claire : gRPC pour les flux internes haute fréquence, REST pour les APIs exposées à l'extérieur ou aux équipes qui ne maîtrisent pas gRPC. Un service mesh comme Istio peut faciliter la coexistence des deux protocoles avec une gestion centralisée.

- Q: Pourquoi ne pas tout faire en gRPC dès le départ si c'est l'objectif final ?
  R: La complexité opérationnelle de gRPC a un coût réel en termes de temps de développement, de debugging, et de formation. Démarrer en REST permet de livrer de la valeur rapidement. Et nos benchmarks montrent que REST est parfaitement capable de gérer la charge de SignalWatch à court terme. La migration vers gRPC peut se faire de manière incrémentale, service par service, sans risque de tout casser.

- Q: Est-ce que la matrice est subjective ? Comment avez-vous attribué les scores ?
  R: Oui, la matrice contient une part de subjectivité dans le choix des poids et des scores. On a ancré les scores sur des données mesurées quand c'était possible — les critères de performance viennent directement du benchmark. Pour les critères qualitatifs comme l'opérabilité, on s'est basés sur l'expérience de mise en oeuvre et sur la documentation de l'écosystème. Une équipe différente avec des contraintes différentes pourrait pondérer autrement et arriver à un résultat différent — c'est le principe même d'une matrice multicritères.

---

## Slide 10 — Conclusion et limites

**Durée suggérée :** 3 minutes

**Ce que vous voyez :** Synthèse des résultats, recommandation finale hybride, limites du benchmark, perspectives d'évolution.

**Ce que vous dites :**

On arrive à la fin de notre présentation. Permettez-moi de synthétiser ce qu'on a appris et d'être transparent sur ce qu'on n'a pas mesuré.

Notre **conclusion principale** : pour SignalWatch, dans sa phase actuelle, REST est le protocole de départ recommandé. Il est plus rapide dans notre benchmark, plus stable sous charge, et beaucoup plus simple à opérer. gRPC est le protocole cible pour les flux haute fréquence à mesure que la plateforme grandit — sa compacité de données (2,7x moins de bande passante) et son support natif du streaming en font l'outil idéal pour les communications capteur-à-service à très grande échelle.

Mais soyons honnêtes sur les **limites de ce benchmark**. Premièrement, l'environnement : on est en loopback réseau sur macOS. Un vrai déploiement cloud avec des latences réseau réelles, des load balancers, et plusieurs instances changerait les chiffres — probablement en faveur de gRPC dont le multiplexage HTTP/2 s'exprime mieux sur des liens à plus haute latence.

Deuxièmement, on n'a pas testé le **streaming gRPC**. C'est pourtant là que gRPC a un avantage structurel pour de l'IoT — une stream persistante pour chaque capteur évite le overhead de connexion à chaque mesure. C'est la prochaine étape d'investigation.

Troisièmement, les outils de benchmark ne sont pas parfaitement comparables. k6 et ghz ont des modèles de charge différents, des métriques différentes — la comparaison directe a des limites intrinsèques.

Quatrièmement, notre implémentation est un prototype — les optimisations de production, le tuning des connexion pools, le placement des services auraient un impact significatif sur les résultats gRPC notamment.

Malgré ces limites, ce benchmark a rempli son objectif : donner à SignalWatch une base empirique solide pour un choix architectural éclairé. La recommandation hybride n'est pas un manque de décision — c'est la réponse adaptée à un contexte où les deux protocoles ont des mérites complémentaires.

Je vous remercie de votre attention. On est disponibles pour toutes vos questions.

**Points clés à souligner :**
- Recommandation : REST maintenant, gRPC pour les flux critiques plus tard
- Limites majeures : environnement loopback, pas de streaming gRPC testé, outils non comparables à 100%
- Le benchmark donne une base empirique, pas une vérité absolue
- L'approche hybride est justifiée par des scores très proches et des cas d'usage complémentaires
- Transparence sur les limites = crédibilité de la recommandation

**Questions possibles :**
- Q: Si vous refaisiez ce benchmark en cloud, quels résultats attendriez-vous ?
  R: Sur un vrai réseau avec 5-10 ms de latence, je m'attends à ce que l'écart REST/gRPC sur la latence absolue s'estompe — les deux seraient dominés par la latence réseau. Mais le throughput et le comportement sous charge resteraient informatifs. Et je m'attends à ce que gRPC soit relativement plus compétitif, car son multiplexage HTTP/2 est plus avantageux sur des liens avec de la latence.

- Q: Quelle serait la prochaine étape concrète pour SignalWatch ?
  R: Trois choses : d'abord, déployer la version REST en production et instrumenter avec du monitoring réel — Prometheus, Grafana. Ensuite, implémenter le streaming gRPC pour le flux d'ingestion des capteurs et mesurer en conditions réelles. Enfin, définir une SLA — par exemple p99 < 10 ms — et monitorer en continu pour décider du bon moment de migration.

- Q: Recommanderiez-vous gRPC pour une startup qui démarre de zéro aujourd'hui ?
  R: Si l'équipe a les compétences et le temps d'investissement, gRPC dès le départ évite une migration future. Mais pour la plupart des startups, REST permet de livrer plus vite et d'apprendre les vrais patterns de charge en production avant de sur-ingénierer. La dette technique d'une migration REST vers gRPC est gérable — la dette technique d'une architecture trop complexe dès le départ peut être paralysante. C'est la raison pour laquelle on recommande REST en premier.

---

## Récapitulatif des données clés

> Ce tableau est un aide-mémoire pour les questions en séance. Ne pas lire à voix haute.

| Métrique | REST | gRPC |
|---|---|---|
| Scénario A — p50 | 0,15 ms | 0,48 ms |
| Scénario A — throughput | 42 030 req/s | 16 113 req/s |
| Scénario B — p50 | 0,14 ms | 0,22 ms |
| Scénario B — throughput | 24 575 req/s | 16 921 req/s |
| Scénario C — p50 (10 VUs) | 0,43 ms | 0,44 ms |
| Scénario C — p50 (100 VUs) | stable ~0,43 ms | 4,53 ms |
| Octets/requête | 410 B | ~153 B |
| Ratio bande passante | 2,7x | — |
| Données/an (SignalWatch) | 2 155 Go | 804 Go |
| Score matrice | 3,90/5 | 3,85/5 |

---

*Document généré pour le projet BenchLab — La Plateforme — 2026*
*Langue : Français | Usage : Notes de présentation orales*
