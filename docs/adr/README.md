# Architecture Decision Records (ADR)

重要度の高い判断を記録する。フォーマットは MADR 軽量版（日本語本文）。

| 番号 | タイトル | ステータス | 日付 |
|------|----------|------------|------|
| [0001](0001-adopt-watchtower-fork-for-container-auto-update.md) | コンテナ自動更新にnicholas-fedor/watchtowerフォークを採用 | 採用 | 2026-08-31 |
| [0002](0002-consolidate-service-layout-under-services-dir.md) | サービスの compose・データ・秘密情報を mini-pc-setup で ~/services/ 配下に集約する | 一部置換 | 2026-10-12 |
| [0003](0003-adopt-bifrost-as-ai-gateway.md) | AI の呼び出しを Bifrost に集約する | 採用 | 2026-10-12 |
| [0004](0004-single-compose-file-for-all-services.md) | サーバーで動かす全サービスを1つの compose ファイルにまとめる | 採用 | 2026-10-12 |
| [0005](0005-back-up-service-data-to-nas-with-restic.md) | サービスのデータを restic で NAS へ毎日バックアップする | 採用 | 2026-10-25 |
| [0006](0006-install-docker-from-official-apt-repo.md) | Docker を Docker 公式の apt リポジトリから Ansible で入れる | 一部置換 | 2026-10-26 |
| [0007](0007-auto-deploy-with-ansible-pull.md) | main の変更を mini-pc 自身が ansible-pull で取り込んで適用する | 採用 | 2026-10-26 |
| [0009](0009-replace-snap-docker-with-official-apt.md) | snap 版 Docker を Docker 公式の apt 版へ入れ替える | 採用 | 2026-10-27 |
