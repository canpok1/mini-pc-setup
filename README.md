# mini-pc-setup

mini-pc のセットアップ用 Ansible プレイブックです。

## 必要なもの
- Ansible
- make

## 前提条件

### GH_TOKEN の設定

plant-diary・health-connect-converter のコンテナイメージは ghcr.io から取得するため（trading-studio のイメージは公開のため不要）、GitHub Personal Access Token (PAT) が必要です。

1. GitHubで `read:packages` スコープを持つPATを作成します。
2. `.devcontainer/.env-template` をコピーして `.devcontainer/.env` を作成します。
3. `GH_TOKEN` に作成したPATを設定します。

```
GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### health-connect-converter のサービスアカウント鍵

`vars/secrets.yml` の `health_connect_converter_sa_key` に、Google Cloud のサービスアカウント鍵（JSON）の中身をそのまま設定してください（`make edit-secrets` で編集）。

### health-connect-converter の監視先ID

`vars/secrets.yml` の `health_connect_converter_drive_folder_id`（監視する Drive フォルダID）と `health_connect_converter_spreadsheet_id`（出力先スプレッドシートID）を設定してください（`make edit-secrets` で編集）。

### trading-studio の開き方

trading-studio は mini-pc の `3000` 番ポートで自宅 LAN 内へ公開します。スマホからは `http://<mini-pc の LAN 内アドレス>:3000/` を開きます。ルーターで外へ転送しないでください。実取引を始める前に Tailscale 経由へ切り替える予定です（trading-studio の ADR 0004）。

あわせて Tailscale Serve で tailnet 内へ HTTPS でも公開します。`make deploy` が Tailscale の導入と Serve の設定を行いますが、次の2つは初回のみ手動で行ってください。

1. Tailscale の管理画面で MagicDNS と HTTPS 証明書を有効にする
2. mini-pc で `sudo tailscale up` を実行してログインする（認証用の鍵を secrets に置かないため）

ログイン前に `make deploy` すると Serve の設定は飛ばされます。ログイン後にもう一度実行してください。スマホからは Tailscale に接続した状態で `https://<mini-pc のマシン名>.<tailnet 名>.ts.net/` を開きます。

**trading-studio は cloudflared 経由で公開しないでください。** インターネットに公開され、ログイン機能の無い画面から誰でも自動取引を操作できてしまいます。

## コンテナの自動更新

plant-diary・health-connect-converter・trading-studio は [nicholas-fedor/watchtower](https://github.com/nicholas-fedor/watchtower)（`containrrr/watchtower` のメンテ継続フォーク。判断の経緯は `docs/adr/0001-adopt-watchtower-fork-for-container-auto-update.md`）により5分間隔で自動更新されます。GHCRの認証はGH_TOKENでのログイン時に生成される `~/.docker/config.json` を再利用するため、追加設定は不要です。

## 使い方

1. `~/.ssh/config` に mini-pc への接続設定を行います。

```
Host mini-pc
    HostName <IP_ADDRESS>
    User <ユーザー名>
    IdentityFile ~/.ssh/id_rsa
```

2. 下記コマンドで接続確認を行います。

```bash
make ping
```

3. プレイブックを実行します。

```bash
make deploy
```

### 機密情報の更新

機密情報は `vars/secrets.yml` に記載されています。必要に応じて次のコマンドで更新してください。

```bash
make edit-secrets
```

## コマンド一覧

`make help` で利用可能なコマンドの一覧を確認できます。

```bash
make help
```
