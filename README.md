# 吉里吉里Z Linux 版 アプリパッケージ

吉里吉里Z (krkrz) 本体と案件のデータをまとめて、Linux 向けの配布物を作るための
外枠リポジトリです。[krkrz_android](https://github.com/wamsoft/krkrz_android) /
krkrz_web / krkrz_ios と同じく、エンジンは `KRKRZ_BASE` 経由で
[krkrz_dev](https://github.com/wamsoft/krkrz_dev) を参照し、ここには Linux 固有の
ビルドとパッケージングだけを置きます。

- 設定は `linux-config.json` 1 本。`cmake` (プラグイン構成) と `assetPack`
  (資材の取り込み) は krkrz_android の `app-config.json` と同じ書式です
- ビルドは Valve の **Steam Linux Runtime 3.0 "sniper" SDK** (Debian 11 / glibc 2.31)
  コンテナで行います。SteamOS・Steam Linux Runtime・glibc 2.31 以降の一般的な
  ディストリビューションで動くバイナリになります (krkrz_dev の
  `src/core/doc/LinuxBuild.md` が基準)
- 出力は「そのまま動くフォルダ」と、それを固めた tar.gz です。Steam のデポ、
  itch.io、GOG などはこのフォルダをそのまま使えます

配布形式の考え方・RPATH・セーブデータの場所・Steam Deck での確認手順などの解説は
krkrz_dev のドキュメント
[Linux 版の配布パッケージ](https://wamsoft.github.io/krkrz_dev/topics/core/linux_package/)
にあります (ソースは krkrz_dev の `doc/topics/core/linux_package.md`)。

## 必要なもの

| 要件 | 備考 |
|---|---|
| docker | ユーザー権限で使えること |
| sniper ビルドイメージ | [steamdev](https://github.com/wamsoft/steamdev) の `bash deckbuild/deckbuild.sh image` で作る `deckbuild-sniper` (別名は環境変数 `KRKRZ_LINUX_IMAGE`) |
| `KRKRZ_BASE` | krkrz_dev を置いた親フォルダ (krkrz_android と同じ規約)。サブモジュールまで初期化済みのこと |
| python3 | 標準ライブラリだけで動く |

## 使い方

```bash
export KRKRZ_BASE=~/kirikiri           # ~/kirikiri/krkrz_dev がある場所

# サンプル案件 (krkrz_dev のコアデモ) をパッケージ化
make all
# → build/linux/package/krkrz-sample/            そのまま動くフォルダ
#   build/linux/dist/krkrz-sample-1.0.0-linux-x86_64.tar.gz

./build/linux/package/krkrz-sample/krkrz-sample   # 引数なしで data/ を自動検出して起動
```

個別の手順は `make build` / `make stage` / `make package`、片付けは `make clean`
(ビルドツリーの docker volume も消す) です。`make native` はコンテナを使わず
手元のツールチェインでビルドします (`VCPKG_ROOT` が必要)。手元の glibc に依存した
バイナリになるので、動作確認用に限ってください。

### 案件フォルダの分離 (PROJECT_DIR)

krkrz_android と同じく、このリポジトリは「共通のビルドシステム」で、案件は別フォルダに
置けます。

| 変数 | 意味 |
|---|---|
| `BUILD_SYSTEM_DIR` | このリポジトリ (固定) |
| `PROJECT_DIR` | 案件フォルダ。`${PROJECT_DIR}/linux-config.json` を読み、`${PROJECT_DIR}/build/linux/` に出力する。未設定ならこのリポジトリ自身 (サンプル案件) |
| `KRKRZ_BASE` | krkrz_dev の親フォルダ |

```bash
PROJECT_DIR=/path/to/mygame make -C /path/to/krkrz_linux all
```

`linux-config.json` の `${...}` と相対パスは `PROJECT_DIR` 基準です。

## linux-config.json

リポジトリ直下のファイルがサンプル兼ひな形です。

| キー | 意味 |
|---|---|
| `name` / `version` | 表示名 / 版 (tar.gz の名前に入る) |
| `exeName` | 実行ファイル名 (krkrz の `KRKRZ_EXE_NAME`)。`<exeName>.cf` もこの名前 |
| `orgName` / `appName` | **セーブデータの場所** を決める組織名 / アプリ名。`<exeName>.cf` に `orgname` / `appname` として書かれる (下記) |
| `arch` | `x64` (既定) / `arm64` |
| `cmake.buildType` | `Release` (既定) / `Debug` |
| `cmake.options` | 追加の CMake 変数 (`{"MASTER": "ON"}` など) |
| `cmake.pluginFolders` / `plugins` / `staticPlugins` | プラグインの検索フォルダ / ビルドするプラグイン (フォルダ名) / 静的リンクするもの。krkrz_android と同じ |
| `config.options` | `<exeName>.cf` に書く追加オプション (先頭の `-` を除いた名前) |
| `desktop` | freedesktop の `.desktop` とアイコン (`id` / `comment` / `categories` / `icon`) |
| `assetPack` | 資材の取り込み。krkrz_android / steamdev の stage と同じ書式 (`mirror` / `flatten`、`include` / `exclude`、**先勝ち**) |
| `package.formats` | `dir` / `tar` (AppImage などは未実装) |

## パッケージの中身

```
krkrz-sample/
  krkrz-sample              実行ファイル (RPATH = $ORIGIN)
  libSDL3.so.0, libSDL3.so.0.x.y
  plugin/*.so               プラグイン (RPATH = $ORIGIN:$ORIGIN/..)
  krkrz-sample.cf           orgname / appname ほか
  <desktop id>.desktop, <desktop id>.svg
  license.txt, licenses/
  data/ または data.xp3     引数なしで起動すると自動検出される
```

- 同梱の SDL3 やプラグインの依存 .so は RPATH (`$ORIGIN`, DT_RPATH) で解決されるので、
  `LD_LIBRARY_PATH` や起動スクリプトは不要です。Steam から起動しても同梱版が使われます
- 先勝ちの順は「エンジン一式 → 生成物 (.cf / .desktop / アイコン) → `assetPack`」です

## セーブデータの場所

Linux 版 krkrz の既定のデータ保存場所は **`~/.local/share/<orgname>/<appname>/`**
(`$XDG_DATA_HOME` があればその下) です。案件ごとに `orgName` / `appName` を決めると
`<exeName>.cf` に入り、作品ごとのフォルダになります。実行ファイルの隣には書かないので、
読み取り専用の場所 (AppImage、Flatpak、`/opt` など) に置いても動きます。

**Steam Cloud** を使う場合は、Steamworks の Auto-Cloud で Linux のルートを
`LinuxXdgDataHome` (= `~/.local/share`)、サブディレクトリを `<orgname>/<appname>` に
してください。

この既定は krkrz_dev 2026-10 の変更です (以前は実行ファイルの隣の `savedata`)。
旧既定のセーブが実行ファイルの隣に残っていると、起動ログに移行を促す警告が出ます。

## Steam Deck で確かめる

出力フォルダは [steamdev](https://github.com/wamsoft/steamdev) でそのまま Deck に送れます。

```bash
steamdev -d <deck> deploy --gameid krkrz_sample \
    --dir build/linux/package/krkrz-sample --command "./krkrz-sample" --start
```

gameid は英数字・`_`・`.` だけです (ハイフン不可)。2026-10-06 にサンプル案件で
Steam Deck (SteamOS 3.8.16、ネイティブ実行) の動作を確認済みです
(`-demotest` で全 24 シーン ok、同梱 SDL3 が読まれ、保存場所は
`/home/deck/.local/share/wamsoft/krkrz-sample/`)。

## 配布形式の今後

| 形式 | 状態 |
|---|---|
| フォルダ / tar.gz (Steam デポ・itch.io・GOG) | ✅ |
| AppImage | 未実装。同じフォルダに `AppRun` を足して `appimagetool` で固める予定 (`.desktop` とアイコンは生成済み) |
| Flatpak (Flathub) | 未定。AppStream メタデータ (`metainfo.xml`) とマニフェストが要る |

xp3 アーカイブは krkrz_android と同じく **案件側で事前に作って取り込みます**
(このリポジトリでは作りません)。作った `*.xp3` を `archive/` に置けば、サンプルの
`assetPack` の `flatten` エントリでパッケージ直下に入ります (`data.xp3` は自動検出)。
暗号化などを含む案件独自のツールがあればそれを使います。暗号化なしの通常の xp3 を作る
共通 CLI は krkrz_dev 側で用意する予定です (krkrz_dev の TODO.md)。
