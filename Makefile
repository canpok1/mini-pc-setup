# 適用先の環境。inventories/<環境>/ を使う（ADR 0010）。例: make deploy ENV=staging
ENV ?= production
INVENTORY := inventories/$(ENV)/hosts.ini

.PHONY: help ping bootstrap deploy edit-secrets

help: ## 使い方の表示
	@echo "使用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'

ping: ## 接続確認
	ansible all -i $(INVENTORY) -m ping

bootstrap: ## 初回のプレイブック実行（sudo のパスワードを聞く）
	ansible-playbook -i $(INVENTORY) playbook.yml --ask-vault-pass --ask-become-pass

# 一度 bootstrap か deploy を通すと、接続ユーザーの sudo はパスワード無しになる（ADR 0007）
deploy: ## プレイブック実行
	ansible-playbook -i $(INVENTORY) playbook.yml --ask-vault-pass

edit-secrets: ## 機密情報の編集
	ansible-vault edit vars/secrets.yml
