# 0009. snap 版 Docker を Docker 公式の apt 版へ入れ替える

- ステータス: 採用
- 日付: 2026-10-27

## コンテキスト

mini-pc の Docker は snap で入っており、ADR 0006 では入れ直さずに残した。snap は1日4回、時刻を選ばず自動更新し、そのたびに dockerd が再起動して全コンテナが止まる。OS の自動更新（ADR 0008）は 5:00 JST にまとめたが、snap の更新はその外にある。Docker の入れ方も Ansible の管理外のまま。サービスのデータはすべてホストのディレクトリ（bind mount）にあり、Docker の管理下には無い。

## 決定

`tasks/docker.yml` で snap 版 Docker を見つけたら `snap remove --purge docker` で消し、続けて ADR 0006 の手順で公式の apt 版を入れる。

- 消す前に名前付きボリュームが無いことを確かめ、あればデプロイを止める
- `--purge` で消す前の自動の退避を作らない（イメージを含み大きい。イメージは取り直せる）
- snap 以外で入れた既存の Docker は、ADR 0006 のとおり入れ直さない

## 結果

- Docker の更新が unattended-upgrades で 5:00 JST にまとまる（更新時は dockerd の再起動でコンテナが一度止まる）
- Docker の入れ方が Ansible の管理下に入り、クリーンインストールと同じ構成になる
- 入れ替えのデプロイで全コンテナが止まり、イメージの取り直しが終わるまで（数分）サービスが止まる。マージがそのままデプロイになる（ADR 0007）ため、止まってよい時間にマージする
- snap 版の dockerd の設定（`/var/snap/docker/current/config/daemon.json`）は引き継がない
- 途中で失敗すると Docker が無い状態で止まる。直して `make deploy` し直す

## 検討した代替案

- **snap のまま更新の時間帯だけ寄せる（`snap set system refresh.timer`）**: 入れ替えの停止は無いが、設定が mini-pc の時計（UTC）で解釈され、snap の更新を延期できる上限もある。Docker の入れ方が管理外のまま残る
- **snap を消さずに apt 版を並べて入れる**: 同じ `/var/run/docker.sock` を取り合い、どちらの dockerd が動くかが起動順で決まる
