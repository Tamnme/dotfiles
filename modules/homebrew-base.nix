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
      "abue-ammar/tinycast"
    ];

    brews = [
      # Languages
      "python"
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
      "borders"
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
      "kubecm"

      # Cloud & security
      #"trivy"
      #"argocd"
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
      "claude-code-router"
      "rtk"
      "agent-browser"
      #"pi-coding-agent"

      # Learning
      "exercism"
    ];

    casks = [
      # AI
      "claude-code@latest"
      "codex"

      # Apps
      #"antigravity-cli"
      #"tinycast"
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
      #"orbstack"
      "ghostty@tip"
      # ponytail: upstream cask break — tunnelblick 8.0.3's API def uses an
      # `uninstall_preflight_steps`/`set_ownership` artifact that no released
      # Homebrew (5.x/6.x/HEAD) can parse, so `brew bundle` aborts. Installed
      # v8.0 stays put (brew can't parse it to uninstall either). Uncomment once
      # the cask is fixed upstream. https://github.com/Homebrew/homebrew-cask
      #"tunnelblick"
      "warp"
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
