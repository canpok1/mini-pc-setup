# 運用

特に断りがなければ、mini-pc 上で実行するコマンドです。どの仕組みも失敗しても通知は来ないため、ここにあるコマンドで確認します。

## 変更を反映する

main へマージすると、15分以内に mini-pc が取り込んで適用します（[自動デプロイ](architecture.md#自動デプロイ)）。**PR のマージがそのままデプロイになります。** 壊れた変更を入れたら revert して main へ入れてください。

```bash
systemctl list-timers mini-pc-deploy.timer     # 次回の実行時刻
systemctl status mini-pc-deploy                # 前回の結果
journalctl -u mini-pc-deploy                   # ログ
sudo systemctl start mini-pc-deploy            # 今すぐ確認（変更が無ければ何もしない）
sudo systemctl disable --now mini-pc-deploy.timer   # 自動デプロイを止める（次の make deploy-production で再開）
```

反映されないときは、上の `status` と `journalctl` で失敗した段階を見ます。

- バックアップで止まっている: `sudo journalctl -u mini-pc-backup` で原因を見る（NAS 側は[初回セットアップ](setup.md#nas-へのバックアップ)の設定を確認）
- `vars/secrets.yml` を開けない: vault のパスワードと `deploy_vault_password` がずれている（[秘密情報を変える](#秘密情報を変える)）
- playbook の適用で失敗している: 原因を直して main へ入れるか、revert する

### main 以外のブランチを試す

本番に入れる前に試すなら、手元でブランチを checkout して [staging 環境](setup.md#staging-環境)へ `make deploy-staging` するのが安全です。本番の mini-pc で試すときは次の手順です。

1. mini-pc で `sudo systemctl disable --now mini-pc-deploy.timer` を実行し、自動デプロイを止める
2. 手元でブランチを checkout して `make deploy-production`。**`make deploy-production` は自動デプロイのタイマーを再び有効にする**ので、試している間に main へ入った変更で上書きされたくなければ、1 をもう一度実行する
3. 試し終わったら、手元で main を checkout して `make deploy-production`（タイマーも有効に戻る）

## サービスを操作する

`~/services/compose.yml` にまとめたサービス（Bifrost・trading-studio・plant-diary）は次のように操作します。

```bash
cd ~/services
docker compose ps                   # 全サービスの状態
docker compose logs -f plant-diary  # 1サービスのログ
docker compose restart bifrost      # 1サービスだけ再起動
docker compose stop trading-studio  # 止める（start で再開）
sudo tailscale serve status         # Tailscale Serve の公開状態
```

compose のサービス名は `bifrost`・`trading-studio`・`plant-diary` です。どれも `restart: unless-stopped` のため、mini-pc の再起動後は自動で上がります。

画面が開けないときは、次の順に確かめます。

1. 端末が Tailscale に接続しているか、URL のポートが合っているか（[README](../README.md#動かすもの)）
2. `docker compose ps` でコンテナが動いているか。止まっていれば `docker compose logs` で原因を見て `restart`
3. `sudo tailscale serve status` に該当のポートがあるか。無ければ `sudo tailscale up` 済みかを確かめ、手元で `make deploy-production`

## 秘密情報を変える

手元で `make edit-secrets` して編集し、main へ入れるか `make deploy-production` します。

Gemini の API キーを変えるときは、2か所を更新してから古いキーを無効にします。plant-diary はまだ Bifrost を経由せず、`gemini_api_key` を直接使っているためです。

- plant-diary: `gemini_api_key` を更新して反映する
- それ以外のアプリ: Bifrost の管理画面で、登録している Gemini のキーを差し替える

vault のパスワードを変えるときは、次の順に行います。自動デプロイは mini-pc に書き出したパスワードで `vars/secrets.yml` を開くため、この2つがずれると失敗し続けます。

1. 手元で `ansible-vault rekey vars/secrets.yml`
2. `make edit-secrets` で `deploy_vault_password` を新しいパスワードにする
3. 手元で `make deploy-production`（mini-pc のパスワードファイルが新しい値になる）
4. すぐに main へ入れる（3 と 4 の間に main へ他の変更が入ると、その回の自動デプロイは失敗する）
5. mini-pc で `sudo systemctl start mini-pc-deploy` と `journalctl -u mini-pc-deploy` で成功を確かめる

## バックアップと復元

root として操作します。

```bash
sudo systemctl status mini-pc-backup     # 前回の結果
sudo journalctl -u mini-pc-backup        # ログ
sudo systemctl start mini-pc-backup      # 今すぐ取る
sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic snapshots'   # 世代の一覧
```

### 復元する

restore で一時的な場所へ取り出してから、手でコピーします。

1. `restic snapshots` で戻したい世代の ID を選ぶ（直近なら `latest` でよい）
2. 取り出す

    ```bash
    sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic restore <ID> --target /tmp/restore'
    ```

3. 対象のサービスを止める（`cd ~/services && docker compose stop <サービス名>`）
4. 取り出したものを元の場所へコピーする。元の絶対パスのまま展開されている（例: `/tmp/restore/home/<ユーザー>/services/trading-studio/data/`）。SQLite の DB だけは `/tmp/restore/var/lib/mini-pc-backup/sqlite/<元の絶対パス>` にある（動作中の DB を安全に複製したもの）ので、こちらを使う
5. サービスを起動する（`docker compose start <サービス名>`）

### 故障後に作り直す

mini-pc を入れ直したときは、同じ `vars/secrets.yml`（`restic_password` と `bifrost_encryption_key` が旧機と同じであること）で[初回セットアップ](setup.md)を行い、その後すぐに上の「復元する」を全サービスに行います。Bifrost の管理画面の設定（管理者・API キー・仮想キー）はデータと一緒に戻るので、作り直しません。

- 適用時のバックアップは、データが1つも無い間は取られません
- 毎日 3:30 の定期バックアップは空のデータでも世代を作ります。**復元を終えるまで `latest` を使わず、故障前の世代を ID で指定してください。** 同じ日の世代は最後の1つしか残らないため、復元が 3:30 をまたぐときは `sudo systemctl stop mini-pc-backup.timer` で止めておき、終わったら `start` で戻します

## OS の自動更新を確認する

```bash
systemctl list-timers apt-daily-upgrade.timer   # 次回の実行時刻
journalctl -u apt-daily-upgrade                 # 前回の結果
less /var/log/unattended-upgrades/unattended-upgrades.log   # 何を更新したか
cat /etc/apt/apt.conf.d/51mini-pc-snapshot      # 参照している時点
```

手で `apt install` したときも、7日前の時点の版が入ります（[OS の自動更新](architecture.md#os-の自動更新)）。最新を入れたいときは `sudo apt-get -o APT::Snapshot= update` してから入れてください。

## 移行の後片付け（手動）

以前の配置から移したときの残りです。確かめてから手で消して構いません。

- `~/src/plant-diary/data/plant_log.db`: 移行前の plant-diary の DB。新しい配置で日記が見えることを確かめてから。clone 自体は撮影スクリプトが使うため消さない
- 手元の clone 直下の `backup/`: 以前の `make deploy` が残したコピー。NAS へのバックアップと復元を確かめてから
