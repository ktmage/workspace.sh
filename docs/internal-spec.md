# Internal specification

[日本語](internal-spec.ja.md) · [README](../README.md) · [External specification](external-spec.md)

## Overview

The CLI reads arguments and the current directory, then reads or updates JSON in the workspace data root. [The external specification](external-spec.md#features) describes its public behavior. Amber produces a single Bash script for distribution.

## Architecture and source layout

`bin/workspace` is a symlink to the generated `workspace.sh`. [main.ab](../src/main.ab) dispatches to the reference and command modules. Both use [io.ab](../src/io.ab) for shared filesystem operations. The command module uses [refs.ab](../src/refs.ab) to resolve workspace ownership.

| File | Responsibility |
| --- | --- |
| [main.ab](../src/main.ab) | Parse top-level arguments, select the data root, and dispatch commands. |
| [refs.ab](../src/refs.ab) | Create, list, and discover workspaces. Validate and update references. Find the enclosing linked worktree. |
| [run.ab](../src/run.ab) | Validate `scripts.json`, select the working directory, and pass arguments to the shell. |
| [io.ab](../src/io.ab) | Read environment values, resolve physical paths, acquire locks, and save data files. |

Edit `src/*.ab` and regenerate `workspace.sh` using the [build instructions](../README.md#rebuild-from-source).

## Processing

### F-001 Create and find workspaces

Creation validates the slug and acquires the root's `.create.lock`. It writes the initial `references.json` into a staging directory under the same root, then moves the initialized directory into place. If the target already exists, the command validates it before returning its path.

For `list` and `here`, `refs.ab` checks direct child directories and validates their references. It collects the readable records and renders the same records as TSV or JSON. `here` also compares the physical current directory against each workspace root and registered directory. The prefix comparison includes the separator to distinguish a directory such as `/src/app` from `/src/application`.

### F-002 Manage references

Adding a reference resolves the physical path and checks its type. Removal takes the saved path as an exact key. Both operations acquire the workspace's `.references.lock`, read the latest JSON, and update only the selected array. A failed lookup leaves the saved file available to readers.

### F-004 Run named commands

The command reads and validates `scripts.json` before choosing a working directory. `refs.ab` walks up from the physical current directory inside the managed worktree layout, checking Git's top-level path, Git directory, and common directory. Walking outward lets it find an enclosing linked worktree from subdirectories. Once the directory is selected, the CLI calls `exec /bin/sh -c` with the stored command string, the script name as `$0`, and each forwarded argument as a separate value.

## Storage

| File | Implementation format |
| --- | --- |
| `references.json` | Object with `directories` and optional `files` arrays. Each array contains unique absolute paths. Creation writes `{"directories":[]}`. |
| `scripts.json` | Object keyed by script name. Each value has a nonempty `command` and may specify a nonempty `cwd`. |

## Concurrency and errors

`io.ab` holds locks on an open file descriptor using macOS `lockf`. Lock acquisition waits up to 15 seconds. The scope is one data root for creation and one workspace file per reference-file write. Writers take the lock before reading the snapshot they will modify.

JSON writes stage a sibling temporary file, then rename it into place. Readers open the current file directly. If a process stops before publishing a file or directory, its staging artifact may remain. Workspace discovery skips hidden staging directories, and repeated creation validates any workspace already published. The exit status and diagnostic rules are in the [external specification](external-spec.md#workspace-selection-and-exit-status).

## Configuration and permissions

The CLI uses `HOME` to select the default root and accepts an absolute `WORKSPACE_HOME`. It resolves an existing root to its physical path. It sets `umask 077` before creating files. A configured command inherits that mask and runs as the current user. Workspace metadata is local to the filesystem.

## Verification

From a clean checkout, compare the output of Amber 0.6.0-alpha with the distributed file.

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab - | cmp - workspace.sh
/bin/bash -n workspace.sh
```

For functional verification, use a temporary absolute `WORKSPACE_HOME`. Run the [README quick start](../README.md#quick-start), then check duplicate creation, shared directory matches, and reference removal. For `run`, use the documented Git worktree layout to check the selected directory, forwarded arguments, and script exit status. Exercise simultaneous creation and reference updates to check the lock boundaries.
