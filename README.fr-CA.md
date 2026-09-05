# OSWAP AI Demonstrator

[English](README.md) · Français canadien · [日本語](README.ja.md) · [Politique linguistique](LANGUAGES.md)

Une implémentation de référence canadienne pour la recherche assistée par IA, locale d'abord, vérifiable et contrôlée par l'humain.

OSWAP AI Demonstrator est un cadre de recherche local avec des moteurs d'inférence remplaçables. Il combine l'appel d'outils par IA, la récupération de l'historique des conversations, la recherche dans des connaissances locales, la recherche sur le Web public, l'évaluation des éléments de preuve, des citations axées sur la provenance, des niveaux de confiance et l'export universel des conversations en fichiers `.txt`.

Créatrice : Nemi Prowse

État : la version 0.4 Release Candidate 3 est une version de développement du cadre portable. Ce projet n'est ni un produit, ni un service, ni une approbation, ni un déploiement de production du gouvernement du Canada.

## Relation avec OSWAP

Le Open-Source World Access Project (OSWAP) est le projet plus vaste consacré à l'accès, à la découverte et à la préservation de logiciels libres et ouverts, ainsi qu'aux outils associés.

OSWAP AI Demonstrator est le composant de démonstration IA d'OSWAP. Il conserve ses propres limites techniques et de publication tout en faisant partie du projet OSWAP.

OSWAP a enregistré `oswap.ca`, `oswap.jp` et `oswap.us` pour une infrastructure future planifiée. Aucun site Web, point d'accès Git, API ou autre service public OSWAP sur ces domaines n'est présenté ici comme actuellement déployé ou en ligne.

Les futurs noms d'hôte publics prévus pour ce projet sont :

- `ai.oswap.ca` — prévu; pas actuellement en ligne
- `ai.oswap.jp` — prévu; pas actuellement en ligne
- `ai.oswap.us` — prévu; pas actuellement en ligne

Ces trois noms sont conçus comme des points d'accès pairs plutôt que comme une copie principale et des copies secondaires. Ils ne doivent pas être présentés comme opérationnels avant la mise en place et la vérification du DNS, du TLS, du routage, de l'hébergement et du protocole Git.

Voir [OSWAP_AI_ENDPOINTS.fr-CA.md](OSWAP_AI_ENDPOINTS.fr-CA.md) pour le contrat prévu de ces points d'accès et les exemples d'adressage de dépôt par ordre des opérations.

## Accès Git prévu

Après le déploiement et la validation de l'infrastructure, les futurs points d'accès OSWAP devraient permettre un accès Git en lecture seule.

Avant ce déploiement, les exemples de syntaxe utilisent volontairement le domaine réservé `.invalid` afin de ne pas ressembler à une instruction réseau utilisable :

```text
git clone https://ai.oswap.invalid
git pull https://ai.oswap.invalid main
```

Ces commandes sont des exemples non opérationnels. Les instructions actuelles de clonage doivent utiliser les URL GitHub ou GitLab vérifiées du projet.

## Principes techniques

Le cadre vise notamment :

- l'exécution locale et la confidentialité par défaut;
- des moteurs d'IA remplaçables;
- une récupération locale des connaissances et de l'historique;
- des contrôles explicites de consentement;
- une journalisation locale des appels d'outils;
- une analyse des éléments de preuve avec examen humain obligatoire;
- des exportations de conversation en texte UTF-8;
- la possibilité de préserver un état logiciel connu indépendamment d'un fournisseur unique.

Le moteur Ollama est pris en charge, mais il ne constitue pas l'identité du cadre. Les adaptateurs d'inférence peuvent être remplacés lorsque leurs capacités sont compatibles avec les fonctions utilisées.

## Installation et détails techniques

La documentation anglaise [README.md](README.md) demeure actuellement le document technique détaillé de référence pour :

- les exigences Python;
- la création de l'environnement virtuel;
- les dépendances verrouillées;
- la configuration des moteurs et modèles;
- les contrôles de sécurité;
- le RAG hybride;
- l'interface graphique;
- la préparation des versions publiques.

Les commandes, noms de variables, noms de fichiers et identifiants techniques doivent rester identiques dans toutes les langues.

## Confidentialité et sécurité

Les historiques de conversation, les embeddings et les pages Web récupérées sont stockés localement selon la configuration et les choix de consentement de l'utilisateur. Une requête Web quitte nécessairement l'appareil lorsqu'elle accède à Internet.

Les contrôles de sécurité du projet constituent des défenses applicatives pratiques et non une garantie de sécurité complète. Toute publication ou utilisation institutionnelle exige une évaluation humaine et un examen adapté au contexte de déploiement.

## Licence et attribution

Le projet est distribué sous licence Apache License 2.0. Consultez [LICENSE](LICENSE), [NOTICE](NOTICE), [AUTHORS.md](AUTHORS.md) et [CITATION.cff](CITATION.cff).

Les contributions futures doivent respecter les licences applicables et préserver l'attribution appropriée.

## Documentation linguistique

La documentation publique prend en charge :

- anglais (`en`);
- français canadien (`fr-CA`);
- japonais (`ja`).

Voir [LANGUAGES.md](LANGUAGES.md) pour les règles de traduction et de synchronisation.
