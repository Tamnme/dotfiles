# dotfiles
My MacOS initial setup and dotfiles configuration

### Requirements:
1. [Install Nix](https://zero-to-nix.com/start/install/)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
2. [Install Nix darwin](https://github.com/LnL7/nix-darwin)
```bash
mkdir -p ~/.config/nix-darwin
mv flake.nix ~/.config/nix-darwin
cd ~/.config/nix-darwin
sed -i '' "s/hostname/$(scutil --get LocalHostName)/" flake.nix
```
### How to
