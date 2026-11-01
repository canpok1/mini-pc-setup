# 適用先の環境ごとにコマンドを分け、環境を書き忘れても本番へ流れないようにする（ADR 0010）
PRODUCTION := -i inventories/production/hosts.ini
STAGING := -i inventories/staging/hosts.ini

.PHONY: help ping-production ping-staging bootstrap-production bootstrap-staging deploy-production deploy-staging edit-secrets

help: ## 使い方の表示
	@echo "使用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-22s %s\n", $$1, $$2}'

ping-production: ## 本番への接続確認
	ansible all $(PRODUCTION) -m ping

ping-staging: ## staging への接続確認
	ansible all $(STAGING) -m ping

bootstrap-production: ## 本番への初回のプレイブック実行（sudo のパスワードを聞く）
	ansible-playbook $(PRODUCTION) playbook.yml --ask-vault-pass --ask-become-pass

bootstrap-staging: ## staging への初回のプレイブック実行（sudo のパスワードを聞く）
	ansible-playbook $(STAGING) playbook.yml --ask-vault-pass --ask-become-pass

# 一度 bootstrap か deploy を通すと、本番の接続ユーザーの sudo はパスワード無しになる（ADR 0011）
deploy-production: ## 本番へのプレイブック実行
	ansible-playbook $(PRODUCTION) playbook.yml --ask-vault-pass

deploy-staging: ## staging へのプレイブック実行
	ansible-playbook $(STAGING) playbook.yml --ask-vault-pass

edit-secrets: ## 機密情報の編集
	ansible-vault edit vars/secrets.yml
