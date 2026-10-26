# 0006. Docker を Docker 公式の apt リポジトリから Ansible で入れる

- ステータス: 採用
- 日付: 2026-10-26

## コンテキスト

全サービスが Docker Compose で動く（ADR 0004）のに、Docker 自体は手で入れており playbook の外にあった。クリーンインストールして SSH で入れるようにしたサーバーへ `make deploy` するだけで環境ができる状態にしたい。既存の mini-pc には手で入れた Docker が動いている。

## 決定

`tasks/docker.yml` で Docker 公式の apt リポジトリから `docker-ce` と `docker-compose-plugin` などを入れ、接続ユーザーを `docker` グループへ加える。

- `docker` コマンドがすでにあれば導入の手順を飛ばす（Tailscale と同じ扱い）
- その場合も `docker compose` が使えなければデプロイを止める

## 結果

- 新しいサーバーでは Docker の手作業が要らない
- 既存の mini-pc の Docker は入れ直さないので、コンテナは止まらない。ただしその Docker の入れ方は Ansible の管理外のまま
- Docker の更新は apt 任せで、バージョンは固定しない

## 検討した代替案

- **Ubuntu の `docker.io` / `docker-compose-v2`**: 追加のリポジトリが要らないが、Compose を含め Docker 公式より古いことが多い。公式の手順と外れるため、困ったときに調べにくい
- **get.docker.com のスクリプト**: 冪等でなく、何をするかが Ansible から見えない
- **Ansible Galaxy のロール（geerlingguy.docker）**: やることは十数タスクで、外部への依存と取得の手順を増やすほどではない
- **既存の Docker があっても公式版で入れ直す**: `docker.io` で入れていると `containerd.io` と衝突し、dockerd の再起動で全コンテナが止まる
