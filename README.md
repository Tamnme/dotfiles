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
- Manual Override (if auto-detect fails or for specific host)
```bash
darwin-rebuild switch --flake .#MT --impure
```

### Note on Dynamic Configuration
The `flake.nix` now uses:
- `HOSTNAME` environment variable for the machine name (falls back to `MT`).
- `SUDO_USER` or `USER` environment variable for the primary user (falls back to `tamnm`).
Use the `--impure` flag with `nix` commands to enable this detection.

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
