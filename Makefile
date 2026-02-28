INVENTORY := inventory.ini

.PHONY: help ping deploy edit-secrets

help: ## 使い方の表示
	@echo "使用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s %s\n", $$1, $$2}'

ping: ## 接続確認
	ansible all -i $(INVENTORY) -m ping

deploy: ## プレイブック実行
	ansible-playbook -i $(INVENTORY) playbook.yml --ask-vault-pass --ask-become-pass

edit-secrets: ## 機密情報の編集
	ansible-vault edit vars/secrets.yml
