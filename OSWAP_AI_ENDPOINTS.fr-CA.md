# Contrat des points d'accès IA d'OSWAP

[English](OSWAP_AI_ENDPOINTS.md) · Français canadien · [日本語](OSWAP_AI_ENDPOINTS.ja.md)

## État

OSWAP a enregistré `oswap.ca`, `oswap.jp` et `oswap.us` pour une infrastructure future planifiée.

Le présent document ne présente aucun de ces domaines ni leurs sous-domaines OSWAP comme un site Web, un point d'accès Git, une API ou un autre service public actuellement déployé. L'enregistrement d'un domaine et la disponibilité d'un service sont des états distincts.

Les sous-domaines d'IA décrits ici demeurent des objectifs de conception tant que le DNS, le TLS, le routage en périphérie, l'hébergement et le traitement du protocole Git n'ont pas été déployés et vérifiés pour chaque point d'accès.

D'ici là, les instructions d'installation et de dépôt doivent utiliser des URL GitHub ou GitLab vérifiées plutôt qu'un domaine détenu par OSWAP.

## Objectif

OSWAP AI Demonstrator devrait éventuellement pouvoir être rejoint au moyen d'identités publiques stables contrôlées par OSWAP, sans dépendre de l'utilisation permanente d'une plateforme Git particulière.

Les noms d'hôte pairs prévus sont :

- `ai.oswap.ca` — prévu; non présenté comme actuellement en ligne
- `ai.oswap.jp` — prévu; non présenté comme actuellement en ligne
- `ai.oswap.us` — prévu; non présenté comme actuellement en ligne

Aucun de ces points d'accès n'est désigné comme copie nationale principale ou canonique. Ils doivent représenter la même identité de projet au moyen de domaines OSWAP pouvant être rejoints indépendamment après leur déploiement et leur vérification.

## Comportement dans un navigateur

Une requête Web ordinaire vers un futur point d'accès déployé devrait afficher une page lisible par une personne pour OSWAP AI Demonstrator, comprenant l'état du projet, la documentation, les emplacements du code source, les renseignements sur les versions, la licence et les renseignements d'intégrité.

## Comportement Git

Les noms d'hôte prévus sont destinés à prendre en charge un accès Git Smart HTTP en lecture seule après le déploiement et la vérification.

La documentation et les tests qui nécessitent volontairement un nom d'hôte non opérationnel DEVRAIENT utiliser un domaine d'exemple réservé ou `.invalid` plutôt qu'un domaine réel détenu par OSWAP. Par exemple :

```text
git clone https://ai.oswap.invalid
git pull https://ai.oswap.invalid main
```

`.invalid` est réservé aux noms qui doivent être manifestement non opérationnels. Les commandes ci-dessus servent uniquement d'exemples de syntaxe et ne sont pas censées être résolues.

Lorsque l'infrastructure OSWAP aura réellement été déployée et vérifiée de façon indépendante, la documentation de production pourra remplacer cet espace réservé par le nom d'hôte déployé approprié.

L'argument de branche est un refspec Git ordinaire. `main` est utilisé ici parce qu'il s'agit actuellement de la branche par défaut; la documentation ne doit pas laisser entendre que ce nom de branche est permanent si le dépôt change ultérieurement.

## Portée initiale du protocole

La première implémentation publique devrait être en lecture seule.

Service Git requis :

- `git-upload-pack` pour les opérations de clonage, de récupération et de mise à jour par pull.

Service non exposé par le point d'accès public initial :

- `git-receive-pack` pour les opérations de push publiques, générales ou non authentifiées.

L'accès en écriture des personnes contributrices devrait continuer de passer par les flux de travail authentifiés des plateformes de dépôt, à moins qu'un point d'accès en écriture distinct et explicitement authentifié soit conçu ultérieurement.

## Indépendance par rapport aux plateformes Git

GitHub et GitLab sont les plateformes actuelles de publication et de collaboration. Les domaines OSWAP planifiés constituent de futures identités publiques, et non des substituts actuellement déployés aux URL de ces plateformes.

La relation future prévue est :

```text
ai.oswap.ca / ai.oswap.jp / ai.oswap.us
        [prévus; pas actuellement en ligne]
                    ↓
identité du projet contrôlée par OSWAP
                    ↓
transport Git / routage du dépôt
                    ↓
GitHub, GitLab ou un autre service compatible
```

Le remplacement d'un service d'arrière-plan ne devrait éventuellement pas obliger les utilisateurs à changer l'adresse publique OSWAP qui leur est fournie.

## Principe des domaines pairs

Les futurs points d'accès `.ca`, `.jp` et `.us` sont des pairs plutôt qu'une hiérarchie principale-miroir. Ils pourront éventuellement utiliser des infrastructures différentes tout en présentant un état de projet équivalent.

L'implémentation ne doit pas prétendre offrir des garanties de synchronisation qui n'ont pas été vérifiées. Lorsque des renseignements d'intégrité seront publiés, ils devraient indiquer l'identifiant de commit et, lorsque pertinent, les sommes de contrôle des versions afin que les utilisateurs puissent comparer les points d'accès.

La possession d'un domaine ne prouve pas qu'un domaine ou sous-domaine précis est opérationnel ni que son état Git est équivalent à celui d'un autre point d'accès. La délégation DNS, le TLS, le routage applicatif, le comportement Git et l'équivalence du contenu sont des questions de vérification distinctes.

## Adressage des dépôts par ordre des opérations

La conception plus large de Twin d'OSWAP explore des identités de dépôt adressées par des expressions. Un identifiant arithmétique canonique comme `9/3` peut être encodé sous la forme DNS-compatible `9d3` lorsqu'une représentation sûre pour le transport est requise.

Des noms futurs proposés sous les domaines enregistrés comprennent :

```text
repo9d3.oswap.ca   [prévu]
repo9d3.oswap.jp   [prévu]
repo9d3.oswap.us   [prévu]
```

Un futur adaptateur PowerShell/Git pourrait aussi utiliser, dans la documentation ou les tests du parseur :

```text
git pull repo(9/3).oswap.invalid
```

puis associer une expression validée à un nom d'hôte de production configuré seulement lorsqu'un profil de déploiement en fournit explicitement un.

Ces exemples constituent des concepts de conception; ils ne signifient pas que les sous-domaines ou cette syntaxe d'adaptateur sont actuellement opérationnels.

## Nommage

- Initiative : Open-Source World Access Project (OSWAP)
- Projet d'IA : OSWAP AI Demonstrator
- Nom du dépôt : `oswap-ai-demonstrator`
- Domaines OSWAP enregistrés et réservés à une infrastructure future : `oswap.ca`, `oswap.jp`, `oswap.us`
- Noms d'hôte IA publics prévus : `ai.oswap.ca`, `ai.oswap.jp`, `ai.oswap.us`
- État actuel du site Web OSWAP : pas encore déployé par ce projet

Les noms de domaine ne changent pas le nom de OSWAP AI Demonstrator. Ils décrivent des adresses futures planifiées contrôlées par OSWAP.

## Principe de déploiement

Le contenu destiné aux navigateurs et le trafic du protocole Git pourront éventuellement partager le même nom d'hôte, mais ils constituent des catégories de requêtes distinctes.

Un domaine ou sous-domaine NE DOIT PAS être décrit comme opérationnel avant que le DNS, le TLS, l'hébergement/routage et le comportement applicatif ou Git pertinents aient été testés depuis un client externe.

Le présent document définit uniquement un contrat futur prévu. Il ne prétend pas que les domaines OSWAP, les sous-domaines d'IA ou les sous-domaines de dépôt adressés par expression sont actuellement en ligne.
