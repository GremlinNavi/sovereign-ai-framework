# Contrat des points d'accès IA d'OSWAP

[English](OSWAP_AI_ENDPOINTS.md) · Français canadien · [日本語](OSWAP_AI_ENDPOINTS.ja.md)

## État

OSWAP possède les domaines publics `oswap.ca`, `oswap.jp` et `oswap.us`.

Les sous-domaines d'IA décrits ici demeurent une infrastructure planifiée. Ils constituent des objectifs de conception tant que le DNS, le TLS, le routage en périphérie et le traitement du protocole Git n'ont pas été déployés et vérifiés pour chaque point d'accès.

## Objectif

OSWAP AI Demonstrator doit pouvoir être rejoint au moyen d'identités publiques stables contrôlées par OSWAP, sans dépendre de l'utilisation permanente d'une plateforme Git particulière.

Les points d'accès pairs prévus sont :

- `https://ai.oswap.ca`
- `https://ai.oswap.jp`
- `https://ai.oswap.us`

Aucun de ces points d'accès n'est désigné comme copie nationale principale ou canonique. Ils doivent représenter la même identité de projet au moyen de domaines OSWAP pouvant être rejoints indépendamment.

## Comportement dans un navigateur

Une requête Web ordinaire vers un point d'accès déployé devrait afficher une page lisible par une personne pour OSWAP AI Demonstrator, comprenant l'état du projet, la documentation, les emplacements du code source, les renseignements sur les versions, la licence et les renseignements d'intégrité.

## Comportement Git

Les mêmes noms d'hôte sont destinés à prendre en charge un accès Git Smart HTTP en lecture seule. Après le déploiement et la vérification, l'interface destinée aux utilisateurs devrait permettre notamment :

```text
git clone https://ai.oswap.ca
git clone https://ai.oswap.jp
git clone https://ai.oswap.us
```

À partir d'une copie de travail Git existante :

```text
git pull https://ai.oswap.ca main
git pull https://ai.oswap.jp main
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
ai.oswap.ca / ai.oswap.jp / ai.oswap.us
        ↓
identité du projet contrôlée par OSWAP
        ↓
transport Git / routage du dépôt
        ↓
GitHub, GitLab ou un autre service compatible
```

Le remplacement d'un service d'arrière-plan ne devrait pas obliger les utilisateurs à changer l'adresse publique OSWAP qui leur est fournie.

## Principe des domaines pairs

Les points d'accès `.ca`, `.jp` et `.us` sont des pairs plutôt qu'une hiérarchie principale-miroir. Ils peuvent initialement utiliser des infrastructures différentes tout en présentant un état de projet équivalent.

L'implémentation ne doit pas prétendre offrir des garanties de synchronisation qui n'ont pas été vérifiées. Lorsque des renseignements d'intégrité sont publiés, ils devraient indiquer l'identifiant de commit et, lorsque pertinent, les sommes de contrôle des versions afin que les utilisateurs puissent comparer les points d'accès.

La possession d'un domaine ne prouve pas qu'un sous-domaine précis est opérationnel ni que son état Git est équivalent à celui d'un autre point d'accès. Le déploiement DNS/TLS et l'équivalence du contenu Git sont des questions de vérification distinctes.

## Adressage des dépôts par ordre des opérations

La conception plus large de Git Push Twin d'OSWAP explore des identités de dépôt adressées par des expressions. Un identifiant arithmétique canonique comme `9/3` peut être encodé sous la forme DNS-compatible `9d3` lorsqu'une représentation sûre pour le transport est requise.

Exemples de noms proposés sous les domaines détenus :

```text
repo9d3.oswap.ca
repo9d3.oswap.jp
repo9d3.oswap.us
```

Un futur adaptateur PowerShell/Git pourrait aussi accepter une forme destinée aux humains comme :

```text
git pull repo(9/3).oswap.ca
```

puis la normaliser avant la résolution DNS et le transport Git vers un nom d'hôte comme `repo9d3.oswap.ca`.

Ces exemples constituent des concepts de conception; ils ne signifient pas que les sous-domaines ou cette syntaxe d'adaptateur sont actuellement opérationnels. Consulter la documentation de Git Push Twin sur l'ordre des opérations pour le modèle d'adressage, de sélection de sous-ensembles, de provenance et de dates de build.

## Nommage

- Initiative : Open-Source World Access Project (OSWAP)
- Projet d'IA : OSWAP AI Demonstrator
- Nom du dépôt : `oswap-ai-demonstrator`
- Domaines OSWAP détenus : `oswap.ca`, `oswap.jp`, `oswap.us`
- Points d'accès IA publics prévus : `ai.oswap.ca`, `ai.oswap.jp`, `ai.oswap.us`

Les noms de domaine ne changent pas le nom de OSWAP AI Demonstrator. Ils fournissent des adresses stables contrôlées par OSWAP.

## Principe de déploiement

Le contenu destiné aux navigateurs et le trafic du protocole Git peuvent partager le même nom d'hôte, mais ils constituent des catégories de requêtes distinctes. La couche de périphérie devrait acheminer les requêtes Web ordinaires vers la page du projet et les requêtes Git Smart HTTP vers un service compatible avec Git.

Le présent document définit uniquement le contrat public prévu. Il ne prétend pas que les sous-domaines d'IA ou de dépôt adressé par expression sont opérationnels avant leur déploiement et leur vérification au moyen de véritables opérations de navigateur, DNS/TLS, `git clone`, `git fetch` et `git pull`.
