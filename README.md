# gitlogue-wrappers

Watch wrappers around gitlogue that automatically replay commits and unstaged file edits in real time.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/the-commits/gitlogue-wrappers/main/install.sh | bash
```

This installs gitlogue, installs `inotify-tools` on Linux or `fswatch` on macOS, and copies the matching wrappers to `~/.local/bin` (override with `INSTALL_DIR`).

On macOS you can also install [gitlogue](https://github.com/unhappychoice/gitlogue) and fswatch via Homebrew:

```bash
brew install gitlogue fswatch
```

## Usage

```bash
gitlogue-commits-watch [repo-dir]
```

Watches for new commits on the current branch and replays them sequentially (default: current directory).

```bash
gitlogue-unstaged-watch [repo-dir]
```

Watches for unstaged changes in tracked files and replays edits on save (default: current directory).

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `GITLOGUE_SPEED` | `10` | Typing speed in milliseconds per character |
| `GITLOGUE_QUIET` | `0.5` | Debounce seconds of calm before replay triggers |
| `GITLOGUE_LATEST` | `0` | Replay current HEAD once at startup (`gitlogue-commits-watch` only) |
