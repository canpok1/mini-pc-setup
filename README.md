# mini-pc-setup

自宅の mini-pc（Ubuntu）に、Docker で動くサービスと運用の仕組みを入れる Ansible プレイブックです。main へのマージで mini-pc に自動で反映されます。

## 動かすもの

| サービス | 内容 | 開き方（Tailscale に接続した端末から） |
|----------|------|------|
| trading-studio | 自動取引 | `https://<マシン名>.<tailnet 名>.ts.net/` |
| plant-diary | 植物の日記 | `https://<マシン名>.<tailnet 名>.ts.net:10000/` |
| Bifrost | AI ゲートウェイ（管理画面） | `https://<マシン名>.<tailnet 名>.ts.net:8443/` |
| health-connect-converter | 健康データの変換 | 画面なし |

あわせて、コンテナと OS の自動更新、NAS へのバックアップ、main の自動デプロイを入れます。

**trading-studio と plant-diary はインターネットへ公開しないでください。** どちらも認証の無い操作があり、誰でも自動取引を操作したり、Gemini の API キーで日記を生成したりできてしまいます。

## 必要なもの

手元のマシンから直接実行します。次のものを入れてください（入れ方は問いません）。

- Ansible と、コレクション `community.docker`（`docker_compose_v2` を含む版）・`ansible.posix`（`ansible` パッケージには両方同梱されている）
- make
- ssh

## クイックスタート

1. `~/.ssh/config` に mini-pc への接続設定を書き、`make ping` で接続を確かめます。

    ```
    Host mini-pc
        HostName <IP_ADDRESS>
        User <ユーザー名>
        IdentityFile ~/.ssh/id_rsa
    ```

2. [初回セットアップ](docs/setup.md)に沿って、秘密情報（`make edit-secrets`）と外部サービスを準備します。
3. `make bootstrap` を実行します（sudo と vault のパスワードを聞きます）。

以降は main へのマージが15分以内に mini-pc へ反映されます。main 以外のブランチを試すときは手元から `make deploy` します。コマンドの一覧は `make help` で見られます。

## ドキュメント

- [初回セットアップ](docs/setup.md): サーバーの前提、秘密情報、Tailscale・NAS・Bifrost の初回設定
- [運用](docs/operations.md): サービスの操作、バックアップと復元、自動デプロイ・自動更新の確認
- [仕組み](docs/architecture.md): サービスの配置、自動デプロイ・自動更新・バックアップがどう動くか
- [ADR](docs/adr/README.md): 判断の記録
