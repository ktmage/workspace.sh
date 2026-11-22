# External specification

[日本語](external-spec.ja.md) · [README](../README.md) · [Internal specification](internal-spec.md)

## Overview

`workspace` organizes related directories, file references, and named shell commands on one Mac. A **workspace** is identified by a **slug**, which also names its directory in the workspace data root. A **managed worktree** is a Git linked worktree rooted inside that workspace's `worktrees/` directory.

## Prerequisites

See [runtime requirements](../README.md#requirements). The current user needs permission to read referenced files and write workspace data for the corresponding operations. `workspace run` also needs permission to enter the chosen working directory and execute the configured command.

## Features

| ID | Feature | Observable result |
| --- | --- | --- |
| [F-001](#f-001-create-and-find-workspaces) | Create and find workspaces | Create a workspace and list all workspaces or all matches for the current directory. |
| [F-002](#f-002-manage-references) | Manage references | Associate an existing directory or file with a workspace and remove that association. |
| [F-004](#f-004-run-named-commands) | Run named commands | List configured commands and run one with arguments in the selected directory. |

## Command reference

### F-001 Create and find workspaces

| Command | Standard output |
| --- | --- |
| `workspace --help` or `workspace -h` | Usage text. |
| `workspace create <slug>` | The absolute path to the workspace. Creating an existing valid workspace returns the same path. |
| `workspace list [--json]` | All valid workspaces, sorted by slug. |
| `workspace here [--json]` | All workspaces whose root or registered directory contains the current directory, including an exact match. |

A slug starts with a lowercase ASCII letter or digit and continues with lowercase ASCII letters, digits, or hyphens. Directory matching compares physical paths at directory boundaries. Each workspace appears once, even if multiple directories match. An empty list succeeds. If an existing references file is invalid or cannot be read, the command prints the readable results and exits with status 1.

Text output from `list` and `here` is one tab-separated row per workspace, with `slug` followed by `path`. With `--json` the shape is the same for both commands.

```json
{"workspaces":[{"slug":"demo","path":"/Users/example/.workspaces/demo"}]}
```

### F-002 Manage references

| Command | Result |
| --- | --- |
| `workspace directory add <slug> <directory>` | Registers the physical path of an existing directory and prints it. |
| `workspace file add <slug> <file>` | Registers the physical path of an existing regular file and prints it. |
| `workspace directory remove <slug> <registered-path>` | Removes the registered absolute path and prints it. |
| `workspace file remove <slug> <registered-path>` | Removes the registered absolute path and prints it. |

Adding a path again succeeds and keeps a single entry. Removal uses the saved absolute path, so it also works after the target is moved or deleted. Removal affects only the reference. File references are stored for lookup in `references.json`. Only directory references contribute to `workspace here`.

### F-004 Run named commands

| Command | Result |
| --- | --- |
| `workspace run --list [--workspace <slug>]` | Prints script names, one per line. With no `scripts.json` it prints an empty list. |
| `workspace run <name> [--workspace <slug>] [-- <args>...]` | Executes the named command using `/bin/sh` and forwards its output and exit status. |

Put a JSON object named `scripts.json` in the workspace directory returned by `create`. Each key is a command name. Each value needs a `command` string and may have a `cwd` string.

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

An absolute `cwd` is used directly. A relative or omitted `cwd` starts from the managed worktree root when it belongs to the selected workspace, and from the workspace directory otherwise. An omitted `cwd` uses that base directory directly. The script name is `$0`. Values after `--` are forwarded as positional arguments without being appended to the command string. Run only commands from a trusted `scripts.json`. They execute with your user permissions.

## Workspace selection and exit status

For `run`, an explicit `--workspace` takes precedence. Without it, `workspace` looks for a managed worktree enclosing the current directory. Outside a managed worktree, pass the slug explicitly. `workspace here` lists associations independently of this selection rule.

To create a managed worktree, use Git to put it under an existing workspace.

```sh
root=$(workspace create demo)
mkdir -p "$root/worktrees"
git -C /path/to/project worktree add --detach "$root/worktrees/review" HEAD
cd "$root/worktrees/review"
workspace run --list
```

| Status | Meaning |
| --- | --- |
| 0 | Success, including an empty result. |
| 1 | An operational failure, such as missing or invalid data, or a partial list. Diagnostics go to standard error. |
| 2 | Invalid usage or arguments, including an omitted workspace when one is required. |
| Script exit status | After `run` starts a script, its exit status is the command's exit status. |

## Data and recovery

The data root is `~/.workspaces/` by default. Set `WORKSPACE_HOME` to an absolute path to override it. Each workspace can hold ordinary files alongside its configuration.

| Path within a workspace | Contents |
| --- | --- |
| `references.json` | The `directories` array and optional `files` array of absolute paths. Created by `workspace create`. |
| `scripts.json` | User-defined shell commands and optional working directories. |
| `worktrees/` | The directory under which linked Git worktrees inherit the workspace. |

Updates issued by this CLI against the same metadata file are serialized. Readers see a complete saved JSON file. If an update is interrupted, inspect the persisted state before retrying.
