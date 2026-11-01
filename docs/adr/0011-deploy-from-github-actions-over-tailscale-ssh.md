# 0011. main の変更を GitHub Actions から Tailscale SSH で本番へ適用する

- ステータス: 採用
- 日付: 2026-10-27
- 置き換え: ADR 0007

## コンテキスト

ADR 0007 では mini-pc 自身が ansible-pull で main を取り込んでいた。このため mini-pc に Ansible・pipx・vault パスワードを置いている。サーバーには動かすサービスに関係するものだけを置きたい。リポジトリは公開。

## 決定

GitHub ホストランナーから Ansible を実行し、Tailscale SSH で本番の mini-pc に入って適用する。

- 実行するのは main への push、毎日 04:00 JST の定期実行、手動実行のとき（`.github/workflows/deploy.yml`）
- ランナーは Tailscale の一時ノード（`tag:ci`）として tailnet に入る。認証は Workload identity federation（GitHub が発行する短命トークン）で、GitHub に Tailscale のシークレットを置かない
- Tailscale の ACL で、`tag:ci` から届くのは `tag:mini-pc` の 22 番だけにし、Tailscale SSH でログインユーザーとして入ることだけを許す。SSH 鍵は使わない
- vault パスワードと接続先は GitHub の Environment `production` に置き、使えるブランチを main に絞る
- mini-pc には Tailscale SSH の有効化と、ログインユーザーのパスワード無し sudo だけを置く。Ansible・pipx・vault パスワードは消す

## 結果

- mini-pc から Ansible と vault パスワードが無くなる
- 失敗すると GitHub から通知メールが届く（ADR 0007 では通知が無かった）
- vault パスワードを GitHub に預ける。GitHub か Tailscale の設定を握られると、sudo できるユーザーで mini-pc に入られる。止めるときは Tailscale の ACL の1行か、信頼する認証情報を消す
- Actions のログは誰でも読める。秘密を扱うタスクには `no_log` を付ける
- 設定は Tailscale の管理画面と GitHub の Settings にもあり、リポジトリだけでは完結しない
- 公開リポジトリで60日間コミットが無いと、GitHub が定期実行を止める

## 検討した代替案

- **ansible-pull を続ける（ADR 0007）**: サーバーに Ansible と vault パスワードが残る
- **本番の mini-pc で self-hosted runner を動かす**: 公開リポジトリでは fork の PR から mini-pc でコードを動かされうる（GitHub 公式も非推奨）。runner は GitHub からの指示を待つ常駐エージェントで、Ansible よりサーバーに置くものが増える
- **Tailscale の OAuth クライアントのシークレットを GitHub に置く**: 動くが、漏れたシークレットはどのジョブからでも使える。Workload identity federation なら Environment `production` のジョブだけに絞れる
- **SSH 鍵を GitHub に置き、OpenSSH で入る**: 鍵の管理が増える。Tailscale SSH なら ACL だけで許可と取り消しができる
- **自宅の別の常時起動の端末から cron で実行する**: 秘密が自宅から出ないが、その端末が実質サーバーになり、止まると更新も止まる
