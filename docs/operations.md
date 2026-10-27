# 運用

特に断りがなければ、mini-pc 上で実行するコマンドです。どの仕組みも失敗しても通知は来ないため、ここにあるコマンドで確認します。

## 変更を反映する

main へマージすると、15分以内に mini-pc が取り込んで適用します（[自動デプロイ](architecture.md#自動デプロイ)）。**PR のマージがそのままデプロイになります。** 壊れた変更を入れたら revert して main へ入れてください。

```bash
systemctl list-timers mini-pc-deploy.timer     # 次回の実行時刻
systemctl status mini-pc-deploy                # 前回の結果
journalctl -u mini-pc-deploy                   # ログ
sudo systemctl start mini-pc-deploy            # 今すぐ確認（変更が無ければ何もしない）
sudo systemctl disable --now mini-pc-deploy.timer   # 自動デプロイを止める（次の make deploy で再開）
```

main 以外のブランチを試すときは、手元から `make deploy` します。

## サービスを操作する

`~/services/compose.yml` にまとめたサービス（Bifrost・trading-studio・plant-diary）は次のように操作します。

```bash
cd ~/services
docker compose ps                 # 全サービスの状態
docker compose restart bifrost    # 1サービスだけ再起動
```

## 秘密情報を変える

手元で `make edit-secrets` して編集し、main へ入れるか `make deploy` します。

vault のパスワードを変えたとき（`ansible-vault rekey`）は、`deploy_vault_password` も同じ値に変えてから手元で `make deploy` してください。古いままだと自動デプロイが `vars/secrets.yml` を開けずに失敗し続けます。

## バックアップと復元

root として操作します。

```bash
sudo systemctl status mini-pc-backup     # 前回の結果
sudo journalctl -u mini-pc-backup        # ログ
sudo systemctl start mini-pc-backup      # 今すぐ取る
sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic snapshots'   # 世代の一覧
```

復元は、取り出したい場所へ restore してから手でコピーします。コピーする前に対象のサービスを止めてください。SQLite の DB は元の場所ではなく `/var/lib/mini-pc-backup/sqlite/` の下に、元の絶対パスのまま入っています（動作中の DB を安全に複製したもの）。

```bash
sudo bash -c 'set -a; . /etc/mini-pc-backup/restic.env; restic restore latest --target /tmp/restore'
```

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
- 手元の `backup/`: 以前の `make deploy` が残したコピー。NAS へのバックアップと復元を確かめてから
