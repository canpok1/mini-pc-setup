# mini-pc-setup

mini-pc のセットアップ用 Ansible プレイブックです。

## 必要なもの

手元のマシンから直接実行します。次のものを入れてください（入れ方は問いません）。

- Ansible と、コレクション `community.docker`（`docker_compose_v2` を含む版）・`ansible.posix`（`ansible` パッケージには両方同梱されている）
- make
- ssh

## 前提条件

### サーバー側

Ubuntu（または Debian）をインストールし、SSH で接続できて sudo できるユーザーがいれば足ります。Docker・Docker Compose は `make deploy` が Docker 公式の apt リポジトリから入れ、接続ユーザーを `docker` グループに加えます（ADR 0006）。snap 版の Docker が入っていれば、消してから apt 版を入れます（ADR 0009。その間すべてのコンテナが止まります）。それ以外の方法で Docker が入っている環境では入れ直しません（`docker compose` が使えなければそこで止まります）。

### GHCR のトークン

plant-diary・health-connect-converter のコンテナイメージは ghcr.io から取得するため（trading-studio のイメージは公開のため不要）、GitHub Personal Access Token (PAT) が必要です。

1. GitHubで `read:packages` スコープを持つPATを作成します。
2. `make edit-secrets` で `ghcr_token` に作成したPATを設定します。

```
ghcr_token: ghp_xxxxxxxxxxxxxxxxxxxx
```

以前は devcontainer の `.devcontainer/.env` の `GH_TOKEN` から読んでいましたが、自動デプロイ（後述）では手元の環境変数が使えないため `vars/secrets.yml` へ移しました。devcontainer も削除済みです。

### health-connect-converter のサービスアカウント鍵

`vars/secrets.yml` の `health_connect_converter_sa_key` に、Google Cloud のサービスアカウント鍵（JSON）の中身をそのまま設定してください（`make edit-secrets` で編集）。

### health-connect-converter の監視先ID

`vars/secrets.yml` の `health_connect_converter_drive_folder_id`（監視する Drive フォルダID）と `health_connect_converter_spreadsheet_id`（出力先スプレッドシートID）を設定してください（`make edit-secrets` で編集）。

### trading-studio の開き方

trading-studio は mini-pc の `127.0.0.1:3000` にだけ公開し、Tailscale Serve で tailnet 内へ HTTPS で公開します（trading-studio の ADR 0003・0004）。自宅 LAN 内でも、Tailscale に接続していない端末からは開けません。`make deploy` が Tailscale の導入と Serve の設定を行いますが、次の2つは初回のみ手動で行ってください。

1. Tailscale の管理画面で MagicDNS と HTTPS 証明書を有効にする
2. mini-pc で `sudo tailscale up` を実行してログインする（認証用の鍵を secrets に置かないため）

ログイン前に `make deploy` すると Serve の設定は飛ばされます。ログイン後にもう一度実行してください。スマホからは Tailscale に接続した状態で `https://<mini-pc のマシン名>.<tailnet 名>.ts.net/` を開きます。

**trading-studio はインターネットへ公開しないでください。** ログイン機能の無い画面から誰でも自動取引を操作できてしまいます。

### plant-diary の開き方

plant-diary も trading-studio と同じく mini-pc の `127.0.0.1:8080` にだけ公開し、Tailscale Serve で tailnet 内へ HTTPS で公開します。アカウント作成の API に認証が無いため、LAN やインターネットへは直接出しません。Tailscale に接続した端末で `https://<mini-pc のマシン名>.<tailnet 名>.ts.net:10000/` を開きます。

**plant-diary もインターネットへ公開しないでください。** 誰でもアカウントを作り、Gemini の API キーを使って日記を生成できてしまいます。

撮影スクリプト（cron）は `~/src/plant-diary` の clone の中にあるため、この clone は消さないでください。移行前の DB（`~/src/plant-diary/data/plant_log.db`）は、新しい配置で日記が見えることを確かめてから手で消して構いません。Gemini の API キーは `vars/secrets.yml` の `gemini_api_key` から渡します（旧配置の `~/src/plant-diary/.env` はもう読みません）。

### NAS へのバックアップの準備

各サービスの `data/` は、自宅 LAN の NAS（Buffalo LS210D、`192.168.2.100`）へ restic で毎日 3:30 にバックアップします（ADR 0005）。`make deploy` も最初に1回バックアップを取り、失敗したらデプロイを止めます。初回のみ次を行ってください。

1. NAS の管理画面で次を行います。
   - ファームウェアを更新し、ファイル共有の設定で SMB2 を有効にする（LS210D は SMB 3.0 に対応していません。SMB2 が無効のままだとマウントで「Server abruptly closed the connection」になります）
   - 共有フォルダー `mini-pc-backup` と、そこにだけ書き込めるユーザーを作る
2. `make edit-secrets` で次の3つを追加します。
   - `backup_nas_username` / `backup_nas_password`: 1 で作ったユーザー
   - `restic_password`: バックアップを暗号化するパスワード。`openssl rand -base64 32` などで作ります。**失くすと全世代が読めなくなります。** 別にも控えてください

NAS の IP や共有名、世代数は `tasks/backup.yml` の変数で変えられます。

### Bifrost（AI ゲートウェイ）の初期設定

アプリからの AI の呼び出しをまとめる [Bifrost](https://github.com/maximhq/bifrost) を動かします（ADR 0002・0003）。Gemini などの本物の API キーは Bifrost の管理画面にだけ登録し、アプリには Bifrost が発行する仮想キーを渡します。初回のみ次を行ってください。

1. `make edit-secrets` で次の2つを追加します。値は `openssl rand -base64 32` などで作ります。
   - `bifrost_encryption_key`: 登録した API キーを暗号化する鍵。**後から変えると登録済みのキーが読めなくなります。** 失くさないよう別に控えてください
   - `bifrost_setup_token`: 最初の管理者アカウントを作るときにだけ使います
2. `make deploy` を実行します。
3. Tailscale に接続した端末で `https://<mini-pc のマシン名>.<tailnet 名>.ts.net:8443/` を開き、設定の Security でパスワード保護を有効にします。Setup token の欄には `bifrost_setup_token` の値を入れます。
4. 同じ画面で「Enforce Virtual Keys on Inference」が有効になっていることを確かめます（仮想キーの無い推論リクエストを断る設定）。
5. Gemini などの API キーを登録し、アプリごとに仮想キーを発行します。

アプリからは Docker ネットワーク `ai` に参加し、`http://bifrost:8080` を呼びます。Bifrost のバージョンは `tasks/bifrost.yml` の `bifrost_version` で固定しており、自動更新はしません。

## サービスの配置

新しい配置（ADR 0002・0004）に移したサービスは、`~/services/compose.yml` の1ファイルにまとめて定義しています。データと秘密情報はサービスごとに `~/services/<サービス名>/data/`・`secrets/` に置きます。今は Bifrost・trading-studio・plant-diary がこの配置で、他のサービスは順次移します。

```bash
cd ~/services
docker compose ps                 # 全サービスの状態
docker compose restart bifrost    # 1サービスだけ再起動
```

## バックアップと復元

mini-pc 上で root として操作します。

```bash
sudo systemctl status mini-pc-backup     # 前回の結果
sudo journalctl -u mini-pc-backup        # ログ
sudo systemctl start mini-pc-backup      # 今すぐ取る
sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic snapshots'   # 世代の一覧
```

世代は日次7・週次4・月次12を残します。同じ日に複数回取った場合は、その日の最後の1つが残ります。残さない世代のデータが NAS から実際に消えるのは、毎週日曜の点検（`mini-pc-backup-check`）のときです。

復元は、取り出したい場所へ restore してから手でコピーします。SQLite の DB は元の場所ではなく `/var/lib/mini-pc-backup/sqlite/` の下に、元の絶対パスのまま入っています（動作中の DB を安全に複製したもの）。コピーする前に対象のサービスを止めてください。

```bash
sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic restore latest --target /tmp/restore'
```

以前の `make deploy` が手元の `backup/` に残したコピーは、NAS へのバックアップと復元を確かめた後で手で消して構いません。

## コンテナの自動更新

plant-diary・health-connect-converter・trading-studio は [nicholas-fedor/watchtower](https://github.com/nicholas-fedor/watchtower)（`containrrr/watchtower` のメンテ継続フォーク。判断の経緯は `docs/adr/0001-adopt-watchtower-fork-for-container-auto-update.md`）により5分間隔で自動更新されます（Bifrost は対象外）。GHCRの認証は `ghcr_token` でのログイン時に生成される `~/.docker/config.json` を再利用するため、追加設定は不要です。

## OS の自動更新

OS と apt で入れたミドルウェア（Tailscale・Docker など）は、Ubuntu 標準の unattended-upgrades が毎日 5:00 JST に更新します（ADR 0008）。

- Ubuntu 公式の更新は、公開から7日たったものだけを入れます（snapshot.ubuntu.com の「7日前の時点」を参照）。セキュリティ修正は待たずに翌朝入れます
- Tailscale・Docker は公開後すぐの版が入ります
- snapshot.ubuntu.com に繋がらない日は、Ubuntu 公式の通常の更新を見送ります（セキュリティ修正と Tailscale・Docker は入ります）
- 再起動が必要な更新のときは、更新の直後に自動で再起動します

失敗しても通知は来ません。mini-pc 上で次のように確認します。

```bash
systemctl list-timers apt-daily-upgrade.timer   # 次回の実行時刻
journalctl -u apt-daily-upgrade                 # 前回の結果
less /var/log/unattended-upgrades/unattended-upgrades.log   # 何を更新したか
cat /etc/apt/apt.conf.d/51mini-pc-snapshot      # 参照している時点
```

手で `apt install` したときも、この時点の版が入ります。最新を入れたいときは `sudo apt-get -o APT::Snapshot= update` してから入れてください。

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

3. プレイブックを実行します。初回（クリーンインストール直後など、sudo にパスワードが要る状態）は `make bootstrap` で sudo のパスワードも入力します。一度通ると sudo がパスワード無しになるため（自動デプロイのため。後述）、2回目以降は `make deploy` で vault のパスワードだけを聞きます。

```bash
make bootstrap   # 初回
make deploy      # 2回目以降
```

### 自動デプロイ

main の変更は mini-pc 自身が取り込みます（ADR 0007）。15分ごとに systemd タイマーが `ansible-pull`（リポジトリを自分で取得し、playbook を自分自身に適用する Ansible のコマンド）を動かし、main に新しいコミットがあったときだけ、`make deploy` と同じ処理（NAS へのバックアップ → playbook の適用）を行います。**PR のマージがそのままデプロイになります。** 壊れた変更を入れたら revert して main へ入れてください。

仕組みを入れるのは手元からのプレイブック実行です。初回のみ次を行ってください。

1. `make edit-secrets` で `deploy_vault_password` に、vault のパスワード（`make deploy` で入力しているもの）と同じ値を追加します。mini-pc の `/etc/mini-pc-deploy/vault-password`（root だけが読める）へ書き出され、自動デプロイが secrets.yml を開くのに使います
2. `make bootstrap` を実行します（sudo のパスワードを聞く版。この時点ではまだ sudo にパスワードが要るため）。ログインユーザーの sudo がパスワード無しになり（自動実行ではパスワードを入力できないため）、以降は `make deploy` で足ります

vault のパスワードを変えたとき（`ansible-vault rekey`）は、`deploy_vault_password` も同じ値に変えてから手元で `make deploy` してください。古いままだと自動デプロイが secrets.yml を開けずに失敗し続けます。

失敗しても通知は来ません。mini-pc 上で次のように確認します。

```bash
systemctl list-timers mini-pc-deploy.timer     # 次回の実行時刻
systemctl status mini-pc-deploy                # 前回の結果
journalctl -u mini-pc-deploy                   # ログ
sudo systemctl start mini-pc-deploy            # 今すぐ確認（変更が無ければ何もしない）
sudo systemctl disable --now mini-pc-deploy.timer   # 自動デプロイを止める（次の make deploy で再開）
```

手元からの `make deploy` は、初回の構築と、main 以外のブランチを試すときに使います。

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
