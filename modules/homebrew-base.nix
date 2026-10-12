{ currentUser, ... }:
{
  homebrew = {
    enable = true;
    user = currentUser;

    taps = [
      "hidetatz/tap"   		# kubecolor
      "oven-sh/bun"       # tap
      "weaveworks/tap"
      "abue-ammar/tinycast"
    ];

    brews = [
      # Languages
      #"python"
      "rustup"
      "pipx"
      "go"
      "bun"

      # git
      "glab"
      "gh"

      # Shell & TUI
      "fish"
      "zsh"
      "zsh-syntax-highlighting"
      "zsh-autocomplete"
      "zsh-autosuggestions"
      "starship"
      "zellij"
      "atuin"
      "herdr"

      # CLI core utilities
      "zoxide"
      #"ffmpeg"
      "eza"
      "fzf"
      "yazi"
      "tree"
      "fastfetch"
      "bat"
      "fd"
      "ripgrep"
      "neovim"
      "jq"
      "yq"
      "ast-grep"
      "telnet"
      "coreutils"
      "mole"

      # Dev tools
      "mise"
      "chezmoi"
      "topgrade"
      "sops"
      "devcontainer"
      "pandoc"
      #"openvpn"
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
      #"hashicorp/tap/terraform"
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
      "kubecm"

      # Cloud & security
      #"trivy"
      #"argocd"
      "awscli"
      "aws-sam-cli"
      "hl"
      "stern"
      "oras"
      "skopeo"
      "kubeconform"

      # AI
      "claude-code-router"
      "rtk"
      "agent-browser"

      # Learning
      "exercism"
    ];

    casks = [
      # AI
      "claude-code@latest"
      "codex"

      # Apps
      "terminal-browser"
      "gcloud-cli"
      #"tinycast"
      "flowvision"
      #"hot"
      "music-decoy"
      #"iina"
      "xkey"
      "loop"

      # Dev tools
      #"orbstack"
      "aws-vault-binary"
      "secretive"
      "zed"
    ];

    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;

      # ponytail: macOS 27 beta is unknown to Homebrew (version lookup returns
      # :dunno, breaking `brew bundle`). Pretend it's Tahoe (26). Remove when
      # brew maps 27.
      extraEnv = {
        HOMEBREW_FAKE_MACOS = "26.0";
      };
    };
  };
}
