# 0010. inventory を production と staging に分け、staging では本番と共有する外部のものに触れない

- ステータス: 採用
- 日付: 2026-10-27

## コンテキスト

動作確認のため、VM や別の Linux 端末に本番と同じ構成を作りたい。今の playbook をそのまま当てると、次の2つが本番に影響する。

- NAS へのバックアップ（ADR 0005）: 本番と同じ restic リポジトリへ書く。`restic forget` はホスト名とパスで世代をまとめるため、ホスト名とユーザー名が本番と同じだと、検証機の世代が本番のその日の世代を押し出して消す。週1回の prune の排他ロックとも競合しうる
- health-connect-converter: 本番と同じサービスアカウント鍵・Drive フォルダ・スプレッドシートを読み書きする

自動デプロイ（ADR 0007）の変更も、本番より先に試せるようにしたい。ただし `ansible-pull` は inventory を使わず、どのマシンでも自分を `localhost` として適用する。

## 決定

- inventory を `inventories/production/` と `inventories/staging/` に分け、`group_vars/all.yml` の `deploy_env` で環境を表す。`make deploy ENV=staging` で切り替え、既定は production
- staging ではバックアップと health-connect-converter を入れない（`when: deploy_env == 'production'`）
- 自動デプロイは staging にも入れる。手元からの適用時に `deploy_env` と追うブランチ（`auto_deploy_branch`）を `/etc/mini-pc-deploy/env.yml` に書き出し、`ansible-pull` へ `--extra-vars` で渡す。ファイルは `LoadCredential` で渡すため、無ければユニットが起動しない
- `deploy_env` が無いか想定外の値なら、playbook の最初で止める

## 結果

- 検証機を作っても NAS と健康ログには触れない。Gemini の API キーや GHCR のトークンは共有のままで、使った分だけ同じ枠を消費する
- staging で `auto_deploy_branch` を変えれば、そのブランチを本番より先に自動デプロイで試せる
- 環境を間違えて指定すると本番扱いになりうる（既定が production）。staging の inventory には本番のホストを書かない
- `host_vars/localhost.yml` にも `deploy_env: production` を置く。この PR を取り込む前のユニットは `env.yml` を渡さないため、本番の初回の自動デプロイだけがこの値を使う

## 検討した代替案

- **staging では自動デプロイを入れない**: 単純だが、自動デプロイ自体の変更を本番より先に試せない
- **staging でも NAS にバックアップし、リポジトリを分ける**: NAS の容量と設定が増える。検証機のデータは守る価値が無い
- **タグ（`--skip-tags`）で飛ばす**: 指定を忘れると本番に影響する。環境を inventory で固定するほうが忘れにくい
