# 外部仕様書

[English](external-spec.md) · [README](../README.ja.md) · [内部仕様書](internal-spec.ja.md)

## 概要

`workspace`は、関連ディレクトリ、ファイルへの参照、名前を付けたシェルコマンドを1台のMacで管理する。**workspace**を識別する**slug**は、データの保存先にあるディレクトリ名と一致する。workspaceの`worktrees/`配下にルートを置くGitのlinked worktreeを**管理対象のworktree**と呼ぶ。

## 前提と制約

[動作環境](../README.ja.md#動作環境)を参照。操作に応じて、参照先ファイルの読み取り権限とworkspaceのデータを書き込む権限が必要。`workspace run`では、実行場所へ移動し、指定されたコマンドを実行できる必要もある。

## 機能一覧

| ID | 機能 | 利用者が得る結果 |
| --- | --- | --- |
| [F-001](#f-001-workspaceを作成する探す) | workspaceを作成する・探す | workspaceを作成し、全件または現在地に関係する候補をすべて一覧できる。 |
| [F-002](#f-002-参照を管理する) | 参照を管理する | 既存のディレクトリやファイルをworkspaceに関連付け、その関連付けを解除できる。 |
| [F-004](#f-004-名前でコマンドを実行する) | 名前でコマンドを実行する | 登録済みの名前を一覧し、作業場所と引数を使ってコマンドを実行できる。 |

## コマンド設計

### F-001 workspaceを作成する・探す

| コマンド | 標準出力 |
| --- | --- |
| `workspace --help`または`workspace -h` | 使い方を表示する。 |
| `workspace create <slug>` | workspaceの絶対パス。有効なworkspaceがすでにあれば、同じパスを返す。 |
| `workspace list [--json]` | 有効なworkspaceをslug順で一覧する。 |
| `workspace here [--json]` | 現在地がworkspace自身の保存先や登録済みの関連ディレクトリと一致するか、その配下にある場合に候補へ含める。 |

slugには小文字の英数字とハイフンが使える。先頭は小文字の英字か数字。現在地と登録パスは、ディレクトリの境界で照合する。同じworkspaceが複数の条件に一致しても一行にまとめる。候補が空でも成功する。既存の参照ファイルを読めないworkspaceがあれば、読めた結果を返し、終了コード1を返す。

`list`と`here`のテキスト出力は、一行につきslugとパスをタブで区切る。`--json`の出力形式は共通。

```json
{"workspaces":[{"slug":"demo","path":"/Users/example/.workspaces/demo"}]}
```

### F-002 参照を管理する

| コマンド | 結果 |
| --- | --- |
| `workspace directory add <slug> <directory>` | 既存ディレクトリの実体パスを登録して表示する。 |
| `workspace file add <slug> <file>` | 既存の通常ファイルの実体パスを登録して表示する。 |
| `workspace directory remove <slug> <registered-path>` | 登録済みの絶対パスを解除して表示する。 |
| `workspace file remove <slug> <registered-path>` | 登録済みの絶対パスを解除して表示する。 |

同じパスを再登録しても一件にまとまる。解除には保存済みの絶対パスを使うので、参照先が移動・削除された後も実行できる。解除するのは関連付けだけ。ファイルへの参照は`references.json`から読める。`workspace here`が照合するのは、workspaceの保存先とディレクトリの関連付け。

### F-004 名前でコマンドを実行する

| コマンド | 結果 |
| --- | --- |
| `workspace run --list [--workspace <slug>]` | 登録済みの名前を一行ずつ表示する。`scripts.json`がなければ空の一覧を返す。 |
| `workspace run <name> [--workspace <slug>] [-- <args>...]` | `/bin/sh`でコマンドを実行し、その出力と終了コードを引き継ぐ。 |

`create`が返したディレクトリに`scripts.json`を作る。トップレベルのキーがコマンド名で、値には`command`の文字列と任意の`cwd`を指定する。

```json
{
  "check": {
    "command": "git status --short \"$@\"",
    "cwd": "/path/to/project"
  }
}
```

```sh
workspace run check --workspace demo -- --branch
```

`cwd`が絶対パスならその場所を使う。相対パスや省略時の基準は、選んだworkspaceが管理するworktree内ではそのworktreeのルートで、それ以外ではworkspaceのディレクトリ。省略すると基準の場所で実行する。コマンド名は`$0`となり、`--`以降はシェルの位置引数として渡す。コマンドは利用者の権限で動くため、内容を信頼できる`scripts.json`を使う。

## 操作先の選択と終了コード

`run`は、まず明示された`--workspace`を使う。指定がなければ現在地を含む管理対象のworktreeから所属先を探す。管理対象のworktree外ではslugを指定する。`workspace here`は操作先の選択と独立して関連先をすべて表示する。

管理対象のworktreeを作るときは、Gitで作成先をworkspaceの配下に指定する。

```sh
root=$(workspace create demo)
mkdir -p "$root/worktrees"
git -C /path/to/project worktree add --detach "$root/worktrees/review" HEAD
cd "$root/worktrees/review"
workspace run --list
```

| 終了コード | 意味 |
| --- | --- |
| 0 | 成功。空の一覧を含む。 |
| 1 | 対象がない、読み書きできない、一覧の一部を読めないなどの操作上の失敗。診断は標準エラーに出る。 |
| 2 | 入力形式の誤り。操作先を選べない場合を含む。 |
| 実行したコマンドの終了コード | `run`がコマンドを起動した後は、その終了コードを引き継ぐ。 |

## データと復旧

既定の保存先は`~/.workspaces/`。`WORKSPACE_HOME`に絶対パスを指定すると変更できる。workspaceには設定ファイルと一緒に通常のファイルも置ける。

| workspace内のパス | 内容 |
| --- | --- |
| `references.json` | 絶対パスの配列`directories`と、任意の`files`。`workspace create`で作成する。 |
| `scripts.json` | 利用者が設定するシェルコマンドと任意の実行場所。 |
| `worktrees/` | 配下に作成したlinked worktreeから、所属するworkspaceを判定する。 |

CLIから同じ管理ファイルに行う更新は順に処理する。読み取り側には保存済みのJSONが見える。処理を中断した場合は、現在の状態を確認してから再実行する。
