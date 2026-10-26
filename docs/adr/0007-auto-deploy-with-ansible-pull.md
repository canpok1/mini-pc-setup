# 0007. main の変更を mini-pc 自身が ansible-pull で取り込んで適用する

- ステータス: 採用
- 日付: 2026-10-26

## コンテキスト

mini-pc-setup の変更は手元から `make deploy` しないと反映されず、マージ済みの変更が止まっていた。`make deploy` は vault パスワード・sudo パスワード・`GH_TOKEN` を手入力で求めるので、自動化するならどの方式でもこれらを mini-pc に置く。リポジトリは公開。

## 決定

systemd タイマーが15分ごとに `ansible-pull --only-if-changed` を動かし、main に変更があれば mini-pc 自身に適用する。

- vault パスワードは secrets.yml の `deploy_vault_password` から root 専用ファイルへ配り、`LoadCredential` で渡す
- `GH_TOKEN` は secrets.yml の `ghcr_token` へ移す
- ログインユーザーの sudo をパスワード無しにする

## 結果

- 外から mini-pc へ指示を送る経路が増えない
- マージがそのままデプロイになる（直前のバックアップが安全網）
- 秘密の中身はもともと mini-pc 上にあり、ログインユーザーは docker グループで root 相当のため、増えるリスクは小さい
- 失敗の通知は無い。vault パスワードを変えたら `deploy_vault_password` も変える

## 検討した代替案

- **GitHub Actions の self-hosted runner**: 公開リポジトリでは fork の PR から mini-pc でコードを動かされうる（GitHub 公式も非推奨）
- **GitHub ホスト runner + Tailscale で ssh**: sudo できる ssh 鍵と vault パスワードを GitHub に預ける
