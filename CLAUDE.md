# CLAUDE.md

吉里吉里Z (krkrz) の Linux 版アプリを作る外枠リポジトリ。エンジンのソースは持たず、
`KRKRZ_BASE`/krkrz_dev を参照してビルドし、案件のデータと一緒にパッケージにまとめる。
使い方と設定項目は README.md が SSOT。

## 構成

- `tools/krkrz_linux.py` — 全工程 (gen / build / stage / package / clean)。標準ライブラリのみ、
  **python 3.9 で動くこと** (sniper SDK コンテナ内でも実行される)
- `tools/stage.py` — steamdev の stage.py の移植。krkrz_android / krkrz_web の
  `assetPack.sources` と同じ書式・意味 (先勝ち・Ant 風グロブ・増分・ハードリンク)。
  書式を変えるときは 3 者を揃える
- `CMakeLists.txt` — krkrz_dev のトップ CMakeLists.txt と同じ手順 (vcpkg マニフェスト統合 →
  project() → CommonExternals → src/core)。プラグイン構成だけ生成ファイル `myapp.cmake` から取る。
  umbrella 側の手順が変わったら追従する
- `linux-config.json` — サンプル案件 (krkrz_dev のコアデモ)

## ビルド環境

配布物のビルドは steamdev deckbuild の sniper SDK イメージ (`deckbuild-sniper`) で行う
(glibc 2.31 基準)。ホストと同じ絶対パスで KRKRZ_BASE / このリポジトリ / PROJECT_DIR を
マウントし、cmake のビルドツリーは named volume。コンテナは root で動くので、
ソース側に出たファイルは最後に chown で戻している。

## 規約

- 共有・公開リポジトリなので、案件・タイトル・取引先を特定できる情報を
  コード・コメント・ドキュメント・コミットメッセージに書かない (krkrz_dev と同じ)
- コメント・ドキュメント・コミットメッセージは日本語
