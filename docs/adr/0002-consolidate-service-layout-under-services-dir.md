# 0002. サービスの compose・データ・秘密情報を mini-pc-setup で ~/services/ 配下に集約する

- ステータス: 採用
- 日付: 2026-10-12

## コンテキスト

アプリの compose ファイルはアプリ本体のリポジトリにあり、mini-pc へ clone して起動している。データの場所・ポート・UID・ネットワークは mini-pc 側の都合なのに、定義がアプリ側に散っている。秘密情報は環境変数で渡しており `docker inspect` で見える。

## 決定

全サービスを次の形に揃え、compose 定義は mini-pc-setup のテンプレートに置く。

```
~/services/<サービス名>/
  compose.yml   テンプレートから生成
  secrets/      1キー1ファイル。vars/secrets.yml から生成
  data/         1000:1000。make deploy のたびに手元へバックアップ
```

- 秘密情報は compose の `secrets:` でファイルとして渡す。環境変数でしか受け取れないツールは、エントリポイントでファイルを読んで環境変数へ入れる
- ポートは `127.0.0.1` にだけ公開し、外へは cloudflared か Tailscale Serve で出す
- 新しいサービスはこの形で入れ、既存サービスは1つずつ移す

## 結果

- mini-pc 内の構成を mini-pc-setup だけで見渡せ、アプリの clone が要らなくなる
- 秘密情報が `docker inspect` に出ない
- アプリの必要な環境変数が変わると mini-pc-setup も直すまで起動しない。watchtower の自動更新で気づかず止まりうる

## 検討した代替案

- **compose をアプリ側に残す**: mini-pc の都合がアプリ側に漏れ続けるため却下
- **環境変数（`.env`）で渡し続ける**: `docker inspect` や子プロセスへ漏れるため却下
