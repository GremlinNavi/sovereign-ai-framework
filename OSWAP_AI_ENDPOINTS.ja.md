# OSWAP AI エンドポイント仕様

[English](OSWAP_AI_ENDPOINTS.md) · [Français canadien](OSWAP_AI_ENDPOINTS.fr-CA.md) · 日本語

## 状態

OSWAP は公開ドメイン `oswap.ca`、`oswap.jp`、`oswap.us` を所有しています。

ここで説明する AI サブドメインは、引き続き計画中のインフラです。各エンドポイントについて DNS、TLS、エッジ・ルーティング、Git プロトコル処理が導入され、検証されるまでは設計目標として扱います。

## 目的

OSWAP AI Demonstrator は、特定の Git フォージを恒久的に利用し続けることに依存せず、OSWAP が管理する安定した公開アドレスから利用できることを目標とします。

計画されているピア・エンドポイントは次の3つです。

- `https://ai.oswap.ca`
- `https://ai.oswap.jp`
- `https://ai.oswap.us`

いずれか一つを国別の主系または正規系として指定しません。3つのエンドポイントは、独立して到達可能な OSWAP ドメインを通じて、同一のプロジェクト・アイデンティティを表すことを目的とします。

## ブラウザーでの動作

導入済みのエンドポイントへ通常のブラウザーからアクセスした場合、OSWAP AI Demonstrator の人間向けプロジェクトページを返すことを想定します。ページには、プロジェクトの状態、ドキュメント、ソースの所在、リリース情報、ライセンス、整合性情報を含めます。

## Git での動作

同じホスト名で、読み取り専用の Git Smart HTTP を提供することを想定します。導入と検証の完了後、利用者向けには次のような操作を可能にする予定です。

```text
git clone https://ai.oswap.ca
git clone https://ai.oswap.jp
git clone https://ai.oswap.us
```

既存の Git ワーキングツリーからは次のように利用します。

```text
git pull https://ai.oswap.ca main
git pull https://ai.oswap.jp main
git pull https://ai.oswap.us main
```

ブランチ引数は通常の Git refspec です。ここでは現在の既定ブランチが `main` であるため例として使用しています。将来リポジトリ構成が変わった場合に、このブランチ名が永久に固定されているような説明は避けます。

## 初期プロトコル範囲

最初の公開実装は読み取り専用とします。

必要な Git サービス:

- clone、fetch、pull のための `git-upload-pack`

初期の公開エンドポイントでは提供しないもの:

- 一般公開または未認証の push のための `git-receive-pack`

コントリビューターの書き込みアクセスは、将来、明示的な認証を備えた専用の書き込みエンドポイントを設計しない限り、認証済みのリポジトリ・ホスト上のワークフローを使用します。

## Git フォージからの独立性

GitHub と GitLab は、公開および共同作業のためのホストであり、プロジェクトの恒久的な公開アイデンティティではありません。

想定される関係は次のとおりです。

```text
ai.oswap.ca / ai.oswap.jp / ai.oswap.us
        ↓
OSWAP が管理するプロジェクト・アイデンティティ
        ↓
Git 転送 / リポジトリ・ルーティング
        ↓
GitHub、GitLab、または他の互換バックエンド
```

バックエンドを変更しても、利用者に案内する OSWAP の公開アドレスを変更する必要がない設計を目指します。

## ピア・ドメイン原則

`.ca`、`.jp`、`.us` のエンドポイントは、主系とミラーの階層ではなくピアです。初期段階では異なるインフラを経由する場合がありますが、同等のプロジェクト状態を提示することを目的とします。

検証していない同期保証を公称してはいけません。公開する整合性情報には、必要に応じてコミット SHA とリリースのチェックサムを含め、利用者が各エンドポイントを比較できるようにします。

親ドメインを所有していること自体は、特定のサブドメインが稼働中であることや、他のエンドポイントと Git 状態が同一であることの証明にはなりません。DNS/TLS の導入と Git コンテンツの同等性は別々に検証する必要があります。

## Order of Operations によるリポジトリ・アドレッシング

OSWAP の Git Push Twin 設計では、数式で指定するリポジトリ・アイデンティティも検討しています。`9/3` のような正規の算術識別子は、DNS などで安全な表現が必要な場合に `9d3` のようなラベルへ符号化できます。

所有するドメイン上の提案例:

```text
repo9d3.oswap.ca
repo9d3.oswap.jp
repo9d3.oswap.us
```

将来の PowerShell/Git ラッパーでは、人間向けの次のような表現を受け付けることも想定できます。

```text
git pull repo(9/3).oswap.ca
```

その後、通常の DNS 解決と Git 転送を行う前に、`repo9d3.oswap.ca` のようなホスト名へ正規化します。

これらは設計上の例であり、現在サブドメインやラッパー構文が稼働しているという意味ではありません。アドレッシング、サブセット選択、プロベナンス、ビルド日付のモデルについては Git Push Twin の Order of Operations ドキュメントを参照してください。

## 命名

- 取り組み: Open-Source World Access Project (OSWAP)
- AI プロジェクト: OSWAP AI Demonstrator
- リポジトリ・スラッグ: `oswap-ai-demonstrator`
- OSWAP が所有するドメイン: `oswap.ca`、`oswap.jp`、`oswap.us`
- 計画中の公開 AI エンドポイント: `ai.oswap.ca`、`ai.oswap.jp`、`ai.oswap.us`

エンドポイント名は OSWAP AI Demonstrator の改名ではありません。OSWAP が管理する安定した公開アドレスを提供するためのものです。

## 導入原則

ブラウザー向けコンテンツと Git プロトコルの通信は同じホスト名を共有できますが、異なる種類のリクエストとして扱います。エッジ層では、通常の Web リクエストをプロジェクトページへ、Git Smart HTTP リクエストを Git 対応バックエンドへ振り分けることを想定します。

本書は予定されている公開仕様のみを定義します。ブラウザー、DNS/TLS、`git clone`、`git fetch`、`git pull` による実際の検証が完了するまでは、AI サブドメインや数式アドレス型リポジトリ・サブドメインが稼働済みであるとは表現しません。
