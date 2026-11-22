# workspace.sh

![対象OS: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![使用言語: Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![ライセンス: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[English](README.md)

複数のディレクトリにまたがる作業を整理するローカルCLI。`workspace`でファイルへの参照と名前を付けたシェルコマンドをまとめて扱う。同じディレクトリを複数のworkspaceに関連付けられる。

**BashとmacOS標準コマンドで動くシェルスクリプトを1本同梱。** `workspace run`でlinked worktreeを判定するときはAppleのGitを使う。Amberは[ソースから再生成するとき](#ソースから再生成する)に使う。

## 動作環境

同梱のシェルスクリプトは、Bash 3.2以降と`/usr/bin/jq`、`/usr/bin/lockf`、`/bin/realpath`などの標準コマンドが使えるmacOSで動作する。`scripts.json`に登録したコマンドの実行には`/bin/sh`を使う。

`workspace run`はlinked worktreeを判定する際にAppleのGit（`/usr/bin/git`）を使う。`/usr/bin/git --version`で確認し、使えない場合は`xcode-select --install`で導入する。 [Command Line Tools for Xcode](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/)

同梱のスクリプトはHomebrewやGitHub CLI（`gh`）なしで動作する。

## 使い始める

リポジトリのルートで`bin/`を`PATH`に加える。その後、整理したいプロジェクトのディレクトリへ移動し、残りのコマンドを実行する。

```sh
export PATH="$PWD/bin:$PATH"
workspace --help

workspace create demo
workspace directory add demo .
workspace here --json
```

`workspace here`は現在地に関連するworkspaceをすべて表示する。`run`の操作先は`--workspace <slug>`で選ぶ。管理対象のworktree内では、この指定を省ける。

## コマンドをインストールする

リポジトリのルートから、生成済みのスクリプトを自分用のコマンド置き場にコピーする。

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 workspace.sh "$HOME/.local/bin/workspace"
export PATH="$HOME/.local/bin:$PATH"
```

## ドキュメント

- [外部仕様書](docs/external-spec.ja.md)ではコマンドの書式、出力、保存データを説明する。
- [内部仕様書](docs/internal-spec.ja.md)ではソースの構成、保存処理、排他制御、検証方法を説明する。

データの既定の保存先は`~/.workspaces/`。変更する場合は`WORKSPACE_HOME`に絶対パスを指定する。

## ソースから再生成する

Amber 0.6.0-alphaを使い、リポジトリのルートで実行する。

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab workspace.sh
/bin/bash -n workspace.sh
```

## ライセンス

[MIT](LICENSE)
