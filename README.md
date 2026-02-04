# dotfiles
My MacOS initial setup and dotfiles configuration

### Requirements:
1. [Install Nix](https://zero-to-nix.com/start/install/)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
```
2. [Install Nix darwin](https://github.com/LnL7/nix-darwin)
- Setup
```bash
mkdir -p ~/.config/nix-darwin
mv flake.nix ~/.config/nix-darwin
cd ~/.config/nix-darwin
sed -i '' "s/hostname/$(scutil --get LocalHostName)/" flake.nix
```
- Install
```bash
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch
```
### How to
- Init
```bash
nix run nix-darwin -- switch --flake ~/.config/nix-darwin#zen8
```
- Rebuild
```bash
darwin-rebuild build --flake ~/.config/nix-darwin#zen8
```

### Common Error
1. Unknown command: brew bundle
```bash
nix flake update
```
2. One day you wake up and then encounter `nix not found`. What to do:
Step 1: Restart your terminal
Step 2: Reinstall Nix

3. `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Connection refused`
run this command
```
sudo launchctl bootstrap system /Library/LaunchDaemons/systems.determinate.nix-daemon.plist
```
