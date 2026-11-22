# workspace.sh

![Platform: macOS](https://img.shields.io/badge/platform-macOS-41454a?logo=apple)
[![Built with Amber](https://img.shields.io/badge/built%20with-Amber-f59e0b)](https://amber-lang.com/)
[![License: MIT](https://img.shields.io/badge/license-MIT-2e7d32)](LICENSE)

[日本語](README.ja.md)

A local CLI for organizing work across directories. Use `workspace` to keep file references and named shell commands together. Multiple workspaces can reference the same directory.

**The included script runs with Bash and standard macOS commands.** `workspace run` uses Apple’s Git to detect linked worktrees. Amber is needed only to [rebuild the script](#rebuild-from-source).

## Requirements

The included shell script runs on macOS with Bash 3.2 or newer and system utilities including `/usr/bin/jq`, `/usr/bin/lockf`, and `/bin/realpath`. It uses `/bin/sh` to run commands from `scripts.json`.

`workspace run` uses Apple's Git (`/usr/bin/git`) to detect linked worktrees. Check that it is available with `/usr/bin/git --version`. If Git is unavailable, run `xcode-select --install`. [Command Line Tools for Xcode](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/)

The included script runs without Homebrew or GitHub CLI (`gh`).

## Quick start

From this checkout, add its `bin/` directory to your shell's `PATH`. Then change to the project directory you want to organize and run the remaining commands there.

```sh
export PATH="$PWD/bin:$PATH"
workspace --help

workspace create demo
workspace directory add demo .
workspace here --json
```

`workspace here` lists every workspace associated with the current directory. Use `--workspace <slug>` to select one for `run`. Inside a managed worktree, you can omit this flag.

## Install the command

Run this from the checkout to copy the generated script into your user bin directory.

```sh
mkdir -p "$HOME/.local/bin"
install -m 755 workspace.sh "$HOME/.local/bin/workspace"
export PATH="$HOME/.local/bin:$PATH"
```

## Documentation

- [External specification](docs/external-spec.md) covers command syntax, output formats, and data.
- [Internal specification](docs/internal-spec.md) covers the source layout, storage, locking, and verification.

Workspace data lives under `~/.workspaces/`. Set `WORKSPACE_HOME` to an absolute path to use a different directory.

## Rebuild from source

Use Amber 0.6.0-alpha and run these commands from the checkout.

```sh
amber build --target bash-3.2 --no-proc bshchk src/main.ab workspace.sh
/bin/bash -n workspace.sh
```

## License

[MIT](LICENSE)
