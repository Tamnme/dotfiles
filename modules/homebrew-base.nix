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
      "oven-sh/bun"       # tap
    ];

    brews = [
      # Languages
      "python"
      "rustup"
      "pipx"
      "go"
      "bun"

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
      "ast-grep"
      "telnet"
      "git-lfs"

      # Dev tools
      "mise"
      "chezmoi"
      "topgrade"
      "sops"
      "devcontainer"
      "pandoc"
      "openvpn"
      "docker-slim"
      "shellcheck"
      "bats-core"
      "poppler"
      "tesseract"

      # IaC
      "ansible"
      "aiac"
      "hashicorp/tap/packer"
      "opentofu"
      "hashicorp/tap/terraform"
      "terragrunt"
      "helm"
      "podman"
      "podman-compose"

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
      "siderolabs/tap/talosctl"

      # Cloud & security
      "trivy"
      "argocd"
      "awscli"
      "aws-sam-cli"
      "spinframework/tap/spin"
      "hl"
      "stern"
      "oras"
      "skopeo"
      "kubeconform"

      # AI
      "claudish"
      "rtk"
      "agent-browser"
      "block-goose-cli"

      # Learning
      "exercism"
    ];

    casks = [
      # AI
      "claude-code@latest"

      # Apps
      "openinterminal"
      "flowvision"
      "hot"
      "only-switch"
      "pearcleaner"
      "music-decoy"
      "iina"
      "keka"
      "middledrag"
      "xkey"
      "loop"

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
