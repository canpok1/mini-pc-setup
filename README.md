# mini-pc-setup

mini-pc のセットアップ用 Ansible プレイブックです。

## 必要なもの
- Ansible

## 使い方

1. `~/.ssh/config` に mini-pc への接続設定を行います。

```
Host mini-pc
    HostName <IP_ADDRESS>
    User <ユーザー名>
    IdentityFile ~/.ssh/id_rsa
```

2. 下記コマンドで接続確認を行います。

```bash
ansible all -i inventory.ini -m ping
```

3. プレイブックを実行します。

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-vault-pass
```

### 機密情報の更新

機密情報は `vars/secrets.yml` に記載されています。必要に応じて次のコマンドで更新してください。

```bash
ansible-vault edit vars/secrets.yml
```

