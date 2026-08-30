# mini-pc-setup

mini-pc のセットアップ用 Ansible プレイブックです。

## 必要なもの
- Ansible
- make

## 前提条件

### GH_TOKEN の設定

plant-diary・health-connect-converter のコンテナイメージは ghcr.io から取得するため、GitHub Personal Access Token (PAT) が必要です。

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
