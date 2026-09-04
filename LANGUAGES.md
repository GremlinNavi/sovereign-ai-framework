# Documentation languages / Langues de documentation / ドキュメント言語

## English

The OSWAP AI Demonstrator and OSWAP-related documentation use three supported public documentation languages:

- English: `en`
- Canadian French: `fr-CA`
- Japanese: `ja`

Official project names, repository slugs, commands, protocol names, file names, URLs, commit hashes, checksums, and other technical identifiers remain unchanged across translations.

English is the source text for technical synchronization unless a document explicitly states otherwise. Translations should preserve meaning rather than copy English syntax literally. A translated document must not claim a feature is operational when the English source describes it as planned, experimental, or unverified.

Where a translation has not yet been completed, the repository should link clearly to the available English source instead of silently omitting the document.

## Français canadien

La documentation publique du OSWAP AI Demonstrator et des éléments liés à OSWAP prend en charge trois langues :

- anglais : `en`
- français canadien : `fr-CA`
- japonais : `ja`

Les noms officiels des projets, les noms de dépôts, les commandes, les noms de protocoles, les noms de fichiers, les URL, les identifiants de commit, les sommes de contrôle et les autres identifiants techniques demeurent inchangés dans les traductions.

Le texte anglais sert de texte source pour la synchronisation technique, sauf indication contraire dans un document. Les traductions doivent préserver le sens plutôt que reproduire littéralement la syntaxe anglaise. Une traduction ne doit pas présenter une fonctionnalité comme opérationnelle lorsque le texte source anglais la décrit comme planifiée, expérimentale ou non vérifiée.

Lorsqu'une traduction n'est pas encore disponible, le dépôt doit fournir un lien clair vers le document anglais plutôt que d'omettre silencieusement l'information.

## 日本語

OSWAP AI Demonstrator および OSWAP 関連の公開ドキュメントでは、次の3言語をサポートします。

- 英語: `en`
- カナダ・フランス語: `fr-CA`
- 日本語: `ja`

正式なプロジェクト名、リポジトリのスラッグ、コマンド、プロトコル名、ファイル名、URL、コミットハッシュ、チェックサム、その他の技術的識別子は、翻訳後も変更しません。

各文書に別途記載がない限り、技術的な同期の基準となる原文は英語です。翻訳では英語の語順を直訳するのではなく、意味と技術的な正確性を維持します。英語版で「計画中」「実験的」「未検証」とされている機能を、翻訳版で稼働済みとして表現してはいけません。

翻訳がまだ用意されていない文書については、情報を省略するのではなく、利用可能な英語版への明確なリンクを提供します。

## File naming convention

Localized Markdown documents use language suffixes where practical:

```text
README.md
README.fr-CA.md
README.ja.md

OSWAP_AI_ENDPOINTS.md
OSWAP_AI_ENDPOINTS.fr-CA.md
OSWAP_AI_ENDPOINTS.ja.md
```

The unsuffixed file is the English source unless the document states otherwise.
