# 0001. コンテナ自動更新にnicholas-fedor/watchtowerフォークを採用

- ステータス: 採用
- 日付: 2026-08-31

## コンテキスト

plant-diary・health-connect-converterは、GitHub ActionsがmainマージのたびにGHCRへ`:latest`イメージを自動pushしているが、mini-PCへの反映は`make deploy`の手動実行が必要だった。外出先からスマホでの指示だけでは最新版を反映できず、帰宅後の手動デプロイが必須になっていた。

## 決定

mini-PC上にコンテナ自動更新ツールを常駐させ、GHCRの新しいイメージを検知して自動でpull・再作成させる。ツールは`containrrr/watchtower`のメンテ継続フォークである`nicholas-fedor/watchtower`を採用する。

- 監視対象: plant-diary・health-connect-converterの2コンテナのみ（cloudflaredは対象外）
- 監視間隔: 5分（`WATCHTOWER_POLL_INTERVAL=300`）
- 更新通知: 行わない（デフォルトで無効、追加設定不要）
- GHCR認証: mini-PC上で既存タスクが生成する`~/.docker/config.json`を`DOCKER_CONFIG`環境変数経由で再利用する

## 結果

- マージ後は待つだけで最新版が反映され、手動デプロイが不要になる。
- 常駐コンテナが1つ増え、Docker socketへのアクセス権を持つ（コンテナ操作全般が可能になるため、信頼できるツールの選定が重要）。
- 採用フォークの監視対象コンテナ名はComposeのデフォルト命名規則からの推定（`<project>-<service>-1`）であり、実機での確認が必要。

## 検討した代替案

- **本家 `containrrr/watchtower` の継続利用**: 2025-12-17にアーカイブ済みでメンテ終了（README冒頭に明記）。最終リリース1.7.1(2023-11)はDocker API 1.25対応で、新しいDocker Engine（API 1.40以上要求）では動作しない可能性があるため却下。
- **WUD (What's Up Docker)**: 2026年8月時点で活発にメンテされている別実装。Web UIや多様な通知先が強みだが、今回は不要な機能であり、設定を書き直すコストが移行メリットを上回るため却下。
- **外出先からの手動デプロイトリガー（webhook等）**: 認証・セキュリティ設計のコストが自動更新方式より高く、既存のCI構成（GHCRへの自動push）と組み合わせれば自動更新方式だけで目的を達成できるため見送り。
