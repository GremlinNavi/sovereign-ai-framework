# Sovereign AI Demonstrator

[English](README.md) · Français canadien · [日本語](README.ja.md) · [Politique linguistique](LANGUAGES.md)

Une implémentation de référence canadienne pour la recherche assistée par IA, locale d'abord, vérifiable et contrôlée par l'humain.

Sovereign AI Demonstrator est un cadre de recherche local avec des moteurs d'inférence remplaçables. Il combine l'appel d'outils par IA, la récupération de l'historique des conversations, la recherche dans des connaissances locales, la recherche sur le Web public, l'évaluation des éléments de preuve, des citations axées sur la provenance, des niveaux de confiance et l'export universel des conversations en fichiers `.txt`.

Créatrice : Nemi Prowse

État : la version 0.4 Release Candidate 3 est une version de développement du cadre portable. Ce projet n'est ni un produit, ni un service, ni une approbation, ni un déploiement de production du gouvernement du Canada.

## Relation avec OSWAP

Le Open-Source World Access Project (OSWAP) est une initiative distincte consacrée à l'accès, à la découverte et à la préservation de logiciels libres et ouverts.

Sovereign AI Demonstrator conserve sa propre identité de projet. OSWAP n'est pas un nouveau nom pour le démonstrateur.

Les futurs points d'accès publics prévus pour ce projet sont :

- `https://ai.oswap.ca`
- `https://ai.oswap.us`

Ces deux adresses sont conçues comme des points d'accès pairs plutôt que comme une copie principale et une copie secondaire. Elles ne doivent pas être présentées comme opérationnelles avant la mise en place et la vérification du DNS, du TLS, du routage et du protocole Git.

Voir [OSWAP_AI_ENDPOINTS.fr-CA.md](OSWAP_AI_ENDPOINTS.fr-CA.md) pour le contrat prévu de ces points d'accès.

## Accès Git prévu

Après le déploiement et la validation de l'infrastructure, les points d'accès OSWAP devraient permettre un accès Git en lecture seule, notamment :

```text
git clone https://ai.oswap.ca
git clone https://ai.oswap.us
```

À partir d'une copie de travail Git existante :

```text
git pull https://ai.oswap.ca main
git pull https://ai.oswap.us main
```

Ces commandes sont des objectifs d'infrastructure tant que les points d'accès n'ont pas été testés avec de véritables opérations Git.

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
