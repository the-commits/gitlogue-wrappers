# gitlogue-wrappers

Tiny watch-wrappers around [gitlogue](https://github.com/unhappychoice/gitlogue)
that keep the cinematic commit replay running *by itself*: save a file and your
raw typing is replayed; make a commit and it plays the moment the current
animation ends. No key presses, no reruns — the terminal just keeps telling the
story of your repo.

## Getting the code

```bash
git clone git@github.com:the-commits/gitlogue-wrappers.git
cd gitlogue-wrappers
```

(or over HTTPS: `https://github.com/the-commits/gitlogue-wrappers.git`)

## 🙏 Homage: gitlogue

This project would not exist without
**[gitlogue](https://github.com/unhappychoice/gitlogue)** by
[@unhappychoice](https://unhappychoice.com) — a cinematic Git commit replay tool
for the terminal that turns your history into a living, animated story, with
realistic typing, tree-sitter syntax highlighting and file-tree transitions.

All the magic on screen is gitlogue. These wrappers only add the *live* part:
inotify-based triggers so the show starts the moment you save or commit. If you
enjoy this, please ⭐️ star the
[upstream project](https://github.com/unhappychoice/gitlogue) and consider
supporting it — it is a gift to the terminal.

```bash
# get gitlogue (choose one)
brew install gitlogue            # macOS / Homebrew
cargo install gitlogue           # via Rust/cargo
sudo pacman -S gitlogue          # Arch Linux
curl -fsSL https://raw.githubusercontent.com/unhappychoice/gitlogue/main/install.sh | bash
```

## The wrappers

### `gitlogue-commits-watch` — follow the committer

Replays every new commit that lands on the current branch, oldest first.
Commits made while an animation is running queue up and play afterwards.
Useful for watching an AI agent (or a colleague) work in real time.

```bash
gitlogue-commits-watch [repo-dir]   # default: current directory
```

### `gitlogue-unstaged-watch` — follow yourself

Launches `gitlogue diff --unstaged` whenever the working tree gets unstaged
changes — i.e. it replays your raw typing as you save. The `.git` directory is
never watched.

```bash
gitlogue-unstaged-watch [repo-dir]   # default: current directory
```

Both scripts quit gitlogue with `q` inside the animation and stop the watcher
with `Ctrl-C`.

## Requirements: inotify / inotify-tools / inotifywait

Both wrappers are driven by **inotify**, the Linux kernel's file-system event
notification subsystem. They talk to it through **inotify-tools**, a small
package whose command-line utility **`inotifywait`** watches directories and
reports events (`modify`, `close_write`, `create`, `move`, `delete`). The
scripts run `inotifywait -m` (monitor mode) so events keep streaming even while
gitlogue is on screen.

Install inotify-tools:

| Distro / system        | Command                                          |
|------------------------|--------------------------------------------------|
| Arch Linux             | `sudo pacman -S --needed inotify-tools`          |
| Debian / Ubuntu        | `sudo apt install inotify-tools`                 |
| Fedora                 | `sudo dnf install inotify-tools`                 |
| openSUSE               | `sudo zypper install inotify-tools`              |
| Alpine                 | `sudo apk add inotify-tools`                     |
| Nix (one-off shell)    | `nix-shell -p inotify-tools`                     |
| NixOS (add to profile) | `nix profile install nixpkgs#inotify-tools`      |

> **macOS:** inotify is a *Linux kernel* feature — there is no inotify, and
> therefore no working `inotifywait`, on macOS. The closest macOS equivalent is
> [`fswatch`](https://github.com/emcrisostomo/fswatch) (`brew install fswatch`),
> which is built on FSEvents; porting the wrappers to fswatch would be a small
> but separate task. Until then, these scripts are Linux-only.

Quick sanity check that the watcher works on your system:

```bash
inotifywait -m -q -e modify,create,delete /tmp &
touch /tmp/inotify-test   # should print an event line
```

## Installing into your local bin (`~/.local/bin`)

`~/.local/bin` is the conventional place for per-user executables. It keeps
these scripts on your `PATH` without needing root, and survives system
upgrades.

### 1. Put the scripts there

From the cloned repository directory — copy (stable) or symlink (stays in sync
with your checkout):

```bash
mkdir -p ~/.local/bin

# symlink (recommended: edits here take effect immediately)
ln -sf "$PWD/gitlogue-commits-watch"  ~/.local/bin/
ln -sf "$PWD/gitlogue-unstaged-watch" ~/.local/bin/

# ...or copy instead
cp gitlogue-commits-watch gitlogue-unstaged-watch ~/.local/bin/
chmod +x ~/.local/bin/gitlogue-*
```

### 2. Make sure `~/.local/bin` is on your `PATH`

**Linux**

Most distros (Debian/Ubuntu, Fedora, Arch with a default `~/.profile`) already
add `~/.local/bin` to `PATH` if the directory exists — check with:

```bash
echo "$PATH" | tr ':' '\n' | grep -x "$HOME/.local/bin"
```

If it is missing, add it to your shell startup file:

```bash
# bash — append to ~/.bashrc
export PATH="$HOME/.local/bin${PATH:+:$PATH}"

# zsh — append to ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"

# fish — one-time command
fish_add_path ~/.local/bin
```

Then reload and verify:

```bash
source ~/.bashrc        # or: source ~/.zshrc ; fish: source ~/.config/fish/config.fish
command -v gitlogue-commits-watch
```

**macOS**

`~/.local/bin` works fine on macOS, but it is **not** on `PATH` by default.
macOS's default shell is zsh, so append to `~/.zshrc` (and ideally
`~/.zshenv`, which is also read by non-interactive shells and scripts):

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshenv
source ~/.zshrc
command -v gitlogue-commits-watch
```

If you use bash on macOS instead, append the same line to `~/.bash_profile`;
for fish, `fish_add_path ~/.local/bin`.

Two macOS gotchas:

- **GUI apps and launchd jobs do not read shell rc files** — anything launched
  from Finder/Spotlight rather than Terminal won't see `~/.local/bin`. That's
  fine here: these are terminal tools.
- `~/.local/bin` must exist *before* you open a new shell if your `~/.profile`
  has an "add it only if it exists" rule (some Linux defaults behave this way).

### 3. Run it

```bash
cd any/git/repo
gitlogue-unstaged-watch    # or: gitlogue-commits-watch
```

If the shell still can't find the command after the steps above, run `hash -r`
(bash/zsh) or `rehash` (fish) to clear the command cache, or simply open a new
terminal.

## Configuration (environment variables)

| Variable          | Default | Meaning                                        |
|-------------------|---------|------------------------------------------------|
| `GITLOGUE_SPEED`  | `10`    | Typing speed in ms per character               |
| `GITLOGUE_QUIET`  | `0.5`   | Debounce: seconds of file-system calm before the replay triggers |
| `GITLOGUE_LATEST` | `0`     | `1` = replay current HEAD once at startup (`gitlogue-commits-watch` only) |

Example:

```bash
GITLOGUE_SPEED=25 GITLOGUE_QUIET=1 gitlogue-unstaged-watch ~/src/myproject
```

## ⭐️ Star & follow gitlogue

These wrappers are just the remote control — the show itself is
[gitlogue](https://github.com/unhappychoice/gitlogue) by
[@unhappychoice](https://unhappychoice.com). If it made your terminal a little
more cinematic, ⭐️ star the repo and follow the project — it deserves every
star it gets.

## Credits

- [**gitlogue**](https://github.com/unhappychoice/gitlogue) by
  [@unhappychoice](https://unhappychoice.com) — the star of the show. ISC
  licensed. Please star it if you like what you see here.
- [**inotify-tools**](https://github.com/inotify-tools/inotify-tools) — the
  `inotifywait` glue between the kernel and these scripts.