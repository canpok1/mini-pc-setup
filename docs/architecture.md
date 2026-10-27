# 仕組み

## サービスの配置

新しい配置（ADR 0002・0004）に移したサービスは、mini-pc の `~/services/compose.yml` の1ファイルにまとめて定義しています。データと秘密情報はサービスごとに `~/services/<サービス名>/data/`・`secrets/` に置きます。今は Bifrost・trading-studio・plant-diary がこの配置で、他のサービスは順次移します。

画面のあるサービスは `127.0.0.1` にだけ公開し、Tailscale Serve で tailnet 内へ HTTPS で公開します。

| サービス | mini-pc 上のポート | Tailscale Serve のポート |
|----------|------|------|
| trading-studio | `127.0.0.1:3000` | 443 |
| plant-diary | `127.0.0.1:8080` | 10000 |
| Bifrost 管理画面 | `127.0.0.1:18080` | 8443 |

## AI の呼び出し（Bifrost）

アプリは Docker ネットワーク `ai` に参加し、`http://bifrost:8080` を Bifrost が発行した仮想キーで呼びます（ADR 0003）。本物の API キーは Bifrost の中にだけあります。ただし plant-diary はまだ移していないため、`gemini_api_key` を直接使います。Bifrost のバージョンは `tasks/bifrost.yml` の `bifrost_version` で固定しており、自動更新はしません。

## 自動デプロイ

main の変更は mini-pc 自身が取り込みます（ADR 0007）。15分ごとに systemd タイマー（`mini-pc-deploy.timer`）が `ansible-pull`（リポジトリを自分で取得し、playbook を自分自身に適用する Ansible のコマンド）を動かし、main に新しいコミットがあったときだけ、`make deploy` と同じ処理（NAS へのバックアップ → playbook の適用）を行います。

自動実行ではパスワードを入力できないため、接続ユーザーの sudo はパスワード無しにし、vault のパスワードは `/etc/mini-pc-deploy/vault-password`（root だけが読める）に置いています。

## コンテナの自動更新

plant-diary・health-connect-converter・trading-studio は [nicholas-fedor/watchtower](https://github.com/nicholas-fedor/watchtower)（`containrrr/watchtower` のメンテ継続フォーク。ADR 0001）により5分間隔で自動更新されます（Bifrost は対象外）。GHCR の認証は `ghcr_token` でのログイン時に生成される `~/.docker/config.json` を再利用します。

## OS の自動更新

OS と apt で入れたミドルウェア（Tailscale・Docker など）は、Ubuntu 標準の unattended-upgrades が毎日 5:00 JST に更新します（ADR 0008）。

- Ubuntu 公式の更新は、公開から7日たったものだけを入れます（snapshot.ubuntu.com の「7日前の時点」を参照）。セキュリティ修正は7日を待たず、次の 5:00 の実行で入れます
- Tailscale・Docker は公開後すぐの版が入ります
- snapshot.ubuntu.com に繋がらない日は、Ubuntu 公式の通常の更新を見送ります（セキュリティ修正と Tailscale・Docker は入ります）
- 再起動が必要な更新のときは、更新の直後に自動で再起動します

## バックアップ

各サービスの `data/` を、NAS の SMB 共有 `mini-pc-backup` へ restic で毎日 3:30 にバックアップします（ADR 0005）。プレイブックの適用の最初にも1回取り、失敗したら適用を止めます。

世代は日次7・週次4・月次12を残します。同じ日に複数回取った場合は、その日の最後の1つが残ります。残さない世代のデータが NAS から実際に消えるのは、毎週日曜の点検（`mini-pc-backup-check`）のときです。
