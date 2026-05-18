# dotfiles
My MacOS initial setup and dotfiles configuration

### Requirements:
1. [Install Nix](https://zero-to-nix.com/start/install/)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
```
2. [Install Nix darwin](https://github.com/LnL7/nix-darwin)
Enter `dotfiles` folder
```
cd dotfiles
```
- Install
```bash
# The configuration now auto-detects your hostname and user.
# The --impure flag is required for environment variable detection.
nix run nix-darwin -- switch --flake . --impure
```

### How to
- Rebuild / Switch
```bash
darwin-rebuild switch --flake . --impure
```
- For new machines (auto-detect hostname)
```bash
HOSTNAME=$(hostname -s) sudo -E nix run nix-darwin -- switch --flake . --impure
```
- Manual Override (if auto-detect fails or for specific host)
```bash
darwin-rebuild switch --flake .#MT --impure
```

### Note on Dynamic Configuration
The `flake.nix` now uses:
- `HOSTNAME` environment variable for the machine name (falls back to `MT`).
- `SUDO_USER` or `USER` environment variable for the primary user (falls back to `tamnm`).
Use the `--impure` flag with `nix` commands to enable this detection.

### Fish Shell Setup
After `darwin-rebuild switch` installs fish via Homebrew, finish the per-user setup:

1. Add fish to `/etc/shells` and set as default
```bash
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

2. Install Fisher (plugin manager)
```fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

3. Install plugins from `configs/fish/fish_plugins`
```fish
fisher update
```
Plugins installed:
- `jorgebucaran/fisher` — plugin manager
- `jethrokuan/z` — frecency directory jump (`z <dir>`)
- `patrickf1/fzf.fish` — fzf bindings (history, files, git status, processes)
- `h-matsuo/fish-color-scheme-switcher` — `scheme` command
- `plttn/fish-eza` — eza wrappers (`l`, `la`, `lc`, …)
- `oh-my-fish/plugin-brew` - integrate Homebrew paths into shell

4. Set color scheme (Catppuccin)
```fish
scheme set catppuccin
```

5. Link configs into `~/.config/fish/`
```bash
mkdir -p ~/.config/fish
ln -sf "$PWD/configs/config.fish"  ~/.config/fish/config.fish
```

#### Fish keybindings
| Key | Action |
|-----|--------|
| `Ctrl+E` | `fzf_edit` — pick file in cwd with fzf, open in `$EDITOR` (nvim). Requires `fd`, `bat`, `fzf` (`brew install fd bat fzf`). |

### Ghostty Setup
Symlink the Ghostty config so this repo is the source of truth:
```bash
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"
ln -sf "$PWD/configs/config.ghostty" "$GHOSTTY_DIR/config.ghostty"
```
Reload Ghostty (`⌘ + Shift + ,`) to pick up changes.

### Zellij Setup
Symlink the Zellij config so this repo is the source of truth:
```bash
mkdir -p ~/.config/zellij
ln -sf "$PWD/configs/zellij.config.kdl" ~/.config/zellij/config.kdl
```
Restart Zellij or detach all sessions for changes to apply.

### Common Errors
1. Unknown command: brew bundle
```bash
nix flake update
```
2. If `nix` is not found after installation:
Step 1: Restart your terminal
Step 2: Reinstall Nix if the issue persists

3. `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Connection refused`
run this command
```
sudo launchctl bootstrap system /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
```
