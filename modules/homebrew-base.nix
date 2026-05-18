{ currentUser, ... }:
{
  homebrew = {
    enable = true;
    user = currentUser;

    taps = [
      "spinframework/tap"	
      "FelixKratz/formulae"	# borders
      "hashicorp/tap"
      "hidetatz/tap"   		# kubecolor
      "MadAppGang/tap" 		# Claudish
    ];

    brews = [
      # Languages
      "python"
      "rustup"
      "pipx"
      "go"

      # Shell & TUI
      "fish"
      "zsh"
      "zsh-syntax-highlighting"
      "zsh-autocomplete"
      "zsh-autosuggestions"
      "starship"
      "zellij"
      "atuin"

      # CLI core utilities
      "zoxide"
      "eza"
      "fzf"
      "yazi"
      "tree"
      "fastfetch"
      "bat"
      "fd"
      "ripgrep"
      "borders"
      "neovim"
      "jq"
      "yq"
      "telnet"

      # Dev tools
      "mise"
      "chezmoi"
      "topgrade"
      "sops"
      "devcontainer"
      "pandoc"
      "openvpn"
      "docker-slim"

      # IaC
      "ansible"
      "aiac"
      "hashicorp/tap/packer"
      "opentofu"
      "hashicorp/tap/terraform"
      "terragrunt"
      "helm"

      # Kubernetes
      "kubectl"
      "kubecolor"
      "kdash-rs/kdash/kdash"
      "k9s"
      "kind"
      "kubie"
      "eksctl"
      "cilium-cli"
      "krew"

      # Cloud & security
      "trivy"
      "argocd"
      "awscli"
      "aws-sam-cli"
      "spinframework/tap/spin"
      "hl"
      "stern"

      # AI
      "claudish"
      "gemini-cli"
      "rtk"

      # Learning
      "exercism"
    ];

    casks = [
      # AI
      "claude-code"

      # Apps
      "flashspace"
      "openinterminal"
      "flowvision"
      "hot"
      "only-switch"
      "pearcleaner"
      "music-decoy"
      "iina"
      "keka"
      "middledrag"

      # Dev tools
      "orbstack"
      "ghostty@tip"
      "tunnelblick"
      "warp"
      "aws-vault-binary"
      "secretive"
      "zed"
    ];

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
  };
}
