# Contrat des points d'accès IA d'OSWAP

[English](OSWAP_AI_ENDPOINTS.md) · Français canadien · [日本語](OSWAP_AI_ENDPOINTS.ja.md)

## État

Infrastructure planifiée. Les points d'accès décrits ici constituent des objectifs de conception tant que le DNS, le TLS, le routage en périphérie et le traitement du protocole Git n'ont pas été déployés et vérifiés.

## Objectif

Sovereign AI Demonstrator doit pouvoir être rejoint au moyen d'identités publiques stables contrôlées par OSWAP, sans dépendre de l'utilisation permanente d'une plateforme Git particulière.

Les points d'accès pairs prévus sont :

- `https://ai.oswap.ca`
- `https://ai.oswap.us`

Aucun de ces points d'accès n'est désigné comme copie nationale principale ou canonique. Les deux doivent représenter la même identité de projet au moyen de domaines OSWAP pouvant être rejoints indépendamment.

## Comportement dans un navigateur

Une requête Web ordinaire vers l'un ou l'autre point d'accès devrait afficher une page lisible par une personne pour Sovereign AI Demonstrator, comprenant l'état du projet, la documentation, les emplacements du code source, les renseignements sur les versions, la licence et les renseignements d'intégrité.

## Comportement Git

Les mêmes noms d'hôte sont destinés à prendre en charge un accès Git Smart HTTP en lecture seule. Après le déploiement et la vérification, l'interface destinée aux utilisateurs devrait permettre notamment :

```text
git clone https://ai.oswap.ca
git clone https://ai.oswap.us
```

À partir d'une copie de travail Git existante :

```text
git pull https://ai.oswap.ca main
git pull https://ai.oswap.us main
```

L'argument de branche est un refspec Git ordinaire. `main` est utilisé ici parce qu'il s'agit actuellement de la branche par défaut; la documentation ne doit pas laisser entendre que ce nom de branche est permanent si le dépôt change ultérieurement.

## Portée initiale du protocole

La première implémentation publique devrait être en lecture seule.

Service Git requis :

- `git-upload-pack` pour les opérations de clonage, de récupération et de mise à jour par pull.

Service non exposé par le point d'accès public initial :

- `git-receive-pack` pour les opérations de push publiques, générales ou non authentifiées.

L'accès en écriture des personnes contributrices devrait continuer de passer par les flux de travail authentifiés des plateformes de dépôt, à moins qu'un point d'accès en écriture distinct et explicitement authentifié soit conçu ultérieurement.

## Indépendance par rapport aux plateformes Git

GitHub et GitLab sont des plateformes de publication et de collaboration; ils ne constituent pas l'identité publique permanente du projet.

La relation prévue est :

```text
ai.oswap.ca / ai.oswap.us
        ↓
identité du projet contrôlée par OSWAP
        ↓
transport Git / routage du dépôt
        ↓
GitHub, GitLab ou un autre service compatible
```

Le remplacement d'un service d'arrière-plan ne devrait pas obliger les utilisateurs à changer l'adresse publique OSWAP qui leur est fournie.

## Principe des domaines pairs

Les points d'accès `.ca` et `.us` sont des pairs plutôt qu'une paire principale-miroir. Ils peuvent initialement utiliser des infrastructures différentes tout en présentant un état de projet équivalent.

L'implémentation ne doit pas prétendre offrir des garanties de synchronisation qui n'ont pas été vérifiées. Lorsque des renseignements d'intégrité sont publiés, ils devraient indiquer l'identifiant de commit et, lorsque pertinent, les sommes de contrôle des versions afin que les utilisateurs puissent comparer les points d'accès.

## Nommage

- Initiative : Open-Source World Access Project (OSWAP)
- Projet d'IA : Sovereign AI Demonstrator
- Nom du dépôt : `sovereign-ai-framework`
- Points d'accès publics prévus : `ai.oswap.ca` et `ai.oswap.us`

Les noms de domaine ne changent pas le nom de Sovereign AI Demonstrator. Ils fournissent des adresses stables contrôlées par OSWAP.

## Principe de déploiement

Le contenu destiné aux navigateurs et le trafic du protocole Git peuvent partager le même nom d'hôte, mais ils constituent des catégories de requêtes distinctes. La couche de périphérie devrait acheminer les requêtes Web ordinaires vers la page du projet et les requêtes Git Smart HTTP vers un service compatible avec Git.

Le présent document définit uniquement le contrat public prévu. Il ne prétend pas que les points d'accès sont opérationnels avant leur déploiement et leur vérification au moyen de véritables commandes `git clone`, `git fetch` et `git pull`.
