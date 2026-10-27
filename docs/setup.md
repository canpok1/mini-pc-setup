# 初回セットアップ

クリーンインストールした mini-pc に初めて適用するまでの手順です。秘密情報はすべて `make edit-secrets` で `vars/secrets.yml` に書きます。全部そろえてから `make bootstrap-production` を実行してください。

## サーバー側の前提

Ubuntu（または Debian）をインストールし、SSH で接続できて sudo できるユーザーがいれば足ります。

Docker・Docker Compose はプレイブックが Docker 公式の apt リポジトリから入れ、接続ユーザーを `docker` グループに加えます（ADR 0006）。snap 版の Docker が入っていれば、消してから apt 版を入れます（ADR 0009。その間すべてのコンテナが止まります）。それ以外の方法で Docker が入っている環境では入れ直しません（`docker compose` が使えなければそこで止まります）。

## GHCR のトークン

plant-diary・health-connect-converter のコンテナイメージは ghcr.io から取得するため、GitHub Personal Access Token (PAT) が必要です（trading-studio のイメージは公開のため不要）。

1. GitHub で `read:packages` スコープを持つ PAT を作成します。
2. `ghcr_token` に設定します。

```yaml
ghcr_token: ghp_xxxxxxxxxxxxxxxxxxxx
```

## health-connect-converter

次の3つを設定します。

- `health_connect_converter_sa_key`: Google Cloud のサービスアカウント鍵（JSON）の中身をそのまま
- `health_connect_converter_drive_folder_id`: 監視する Drive フォルダ ID
- `health_connect_converter_spreadsheet_id`: 出力先スプレッドシート ID

## plant-diary

- `gemini_api_key`: Gemini の API キー

撮影スクリプト（cron）は mini-pc の `~/src/plant-diary` の clone の中にあるため、この clone は消さないでください。

## Tailscale

trading-studio・plant-diary・Bifrost の管理画面は mini-pc の `127.0.0.1` にだけ公開し、Tailscale Serve で tailnet 内へ HTTPS で公開します（trading-studio の ADR 0003・0004）。自宅 LAN 内でも、Tailscale に接続していない端末からは開けません。

Tailscale の導入と Serve の設定はプレイブックが行いますが、次の2つは手動で行ってください。

1. `make bootstrap-production` の前に、Tailscale の管理画面で MagicDNS と HTTPS 証明書を有効にする
2. `make bootstrap-production` の後に、mini-pc で `sudo tailscale up` を実行してログインする（Tailscale はプレイブックが入れるため。認証用の鍵は secrets に置かない）

ログイン前の実行では Serve の設定は飛ばされます。ログイン後に手元から `make deploy-production` をもう一度実行してください。

## NAS へのバックアップ

各サービスのデータを自宅 LAN の NAS（Buffalo LS210D、`192.168.2.100`）へ restic でバックアップします（ADR 0005）。

1. NAS の管理画面で次を行います。
   - ファームウェアを更新し、ファイル共有の設定で SMB2 を有効にする（LS210D は SMB 3.0 に対応していません。SMB2 が無効のままだとマウントで「Server abruptly closed the connection」になります）
   - 共有フォルダー `mini-pc-backup` と、そこにだけ書き込めるユーザーを作る
2. 次の3つを設定します。
   - `backup_nas_username` / `backup_nas_password`: 1 で作ったユーザー
   - `restic_password`: バックアップを暗号化するパスワード。`openssl rand -base64 32` などで作ります。**失くすと全世代が読めなくなります。** 別にも控えてください

NAS の IP や共有名、世代数は `tasks/backup.yml` の変数で変えられます。

## Bifrost（AI ゲートウェイ）

アプリからの AI の呼び出しをまとめる [Bifrost](https://github.com/maximhq/bifrost) を動かします（ADR 0002・0003）。Gemini などの本物の API キーは Bifrost の管理画面に登録し、アプリには Bifrost が発行する仮想キーを渡します（plant-diary だけは移行前のため `gemini_api_key` を直接使います）。

1. 次の2つを設定します。値は `openssl rand -base64 32` などで作ります。
   - `bifrost_encryption_key`: 登録した API キーを暗号化する鍵。**後から変えると登録済みのキーが読めなくなります。** 失くさないよう別に控えてください
   - `bifrost_setup_token`: 最初の管理者アカウントを作るときにだけ使います
2. プレイブックを実行した後、Tailscale に接続した端末で `https://<マシン名>.<tailnet 名>.ts.net:8443/` を開き、設定の Security でパスワード保護を有効にします。Setup token の欄には `bifrost_setup_token` の値を入れます。
3. 同じ画面で「Enforce Virtual Keys on Inference」が有効になっていることを確かめます（仮想キーの無い推論リクエストを断る設定）。
4. Gemini などの API キーを登録し、アプリごとに仮想キーを発行します。

## 適用する

```bash
make bootstrap-production
```

sudo と vault のパスワードを聞きます。一度通ると接続ユーザーの sudo がパスワード無しになり（自動デプロイでは入力できないため。ADR 0011）、以降の手元からの実行は `make deploy-production`（vault のパスワードだけを聞く）で足ります。

適用の最初に NAS へのバックアップを1回取り、失敗したらそこで止まります。

## 自動デプロイ

main の変更を GitHub Actions から本番へ適用するための設定です（仕組みは[仕組み](architecture.md#自動デプロイ)）。Tailscale と GitHub の画面で行います。mini-pc 側の Tailscale SSH は playbook が有効にするので、先に Tailscale にログインして `make deploy-production` を通しておきます。

### Tailscale

1. Access controls の JSON に次を足す。`<user>` は mini-pc のログインユーザー
   - `tagOwners` に `"tag:ci": ["autogroup:admin"]` と `"tag:mini-pc": ["autogroup:admin"]`
   - 通信の許可に `tag:ci` → `tag:mini-pc:22`。既存の許可が `src: ["*"]` なら `["autogroup:member"]` に絞る（`tag:ci` がどこへでも届かないように）
   - `ssh` に次の2行。2行目は自分の端末から tailnet 経由で入るためのもの（タグを付けると既定のルールが効かなくなる）
     ```json
     {"action": "accept", "src": ["tag:ci"], "dst": ["tag:mini-pc"], "users": ["<user>"]},
     {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:mini-pc"], "users": ["<user>"]}
     ```
2. Machines で mini-pc に `tag:mini-pc` を付ける（1 の後に行う）
3. Settings → Trust credentials で OpenID Connect の認証情報を作る
   - Issuer: GitHub
   - Subject: `repo:canpok1/mini-pc-setup:environment:production`
   - Scope: Auth Keys の書き込み、タグ: `tag:ci`

### GitHub

リポジトリの Settings → Environments に `production` を作り、Deployment branches を `main` だけにします。そこへ次を登録します。

| 種類 | 名前 | 値 |
|------|------|----|
| Secret | `TS_OAUTH_CLIENT_ID` | Tailscale の 3 で発行された Client ID |
| Secret | `TS_AUDIENCE` | 同じく Audience |
| Secret | `ANSIBLE_VAULT_PASSWORD` | vault のパスワード |
| Variable | `DEPLOY_HOST` | mini-pc の MagicDNS 名（`mini-pc.<tailnet 名>.ts.net`） |
| Variable | `DEPLOY_USER` | mini-pc のログインユーザー |

Actions の画面で Deploy を手動実行し、通ることを確かめます。

## staging 環境

VM や別の Linux 端末に、本番と同じ構成を作って動作を確かめられます（ADR 0010）。秘密情報は本番と同じ `vars/secrets.yml` を使います。

1. `~/.ssh/config` に `Host staging` で検証機への接続設定を書く（`mini-pc` と同じ形）
2. `make ping-staging` で接続を確かめ、`make bootstrap-staging` で適用する
3. Tailscale を使うなら、検証機でも `sudo tailscale up` してから `make deploy-staging` をもう一度実行する

staging では NAS へのバックアップと health-connect-converter を入れません。どちらも本番と同じ NAS・スプレッドシートを読み書きするためです。自動デプロイも入れません（サーバーに Ansible を入れない）。変更は手元から `make deploy-staging` で入れます。Gemini の API キー（plant-diary）は本番と共有なので、使った分だけ同じ枠を消費します。

**`inventories/staging/hosts.ini` に本番のホストを書かないでください。** 本番の mini-pc に staging の設定が適用され、デプロイ前のバックアップが飛ばされます。
