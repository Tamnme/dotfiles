{
  description = "MacOs nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    currentUser = let
      sudoUser = builtins.getEnv "SUDO_USER";
      envUser = builtins.getEnv "USER";
    in if sudoUser != "" then sudoUser
       else if envUser != "" && envUser != "root" then envUser
       else "tamnm";

    configuration = { pkgs, ... }: {
			nix = {
				enable = false;
				# ... other nix options if any ...
			};
      nixpkgs.config.allowUnfree = true;
      # nix.configureBuildUsers = true; # Configure new nixbld User for MacOS Sequoia
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
				pkgs.mkalias
				pkgs.tmux
				pkgs.devenv
      ];
    homebrew.taps = [
      "gofireflyio/aiac"
      "spinframework/tap"
      "FelixKratz/formulae"
      "hashicorp/tap"
      "hidetatz/tap"
      "MadAppGang/tap" #Claudish
    ];
		homebrew = {
			enable = true;
			user = currentUser;
			brews = [
        ## Language
        "python"
        "rustup"
        "pipx"
        ## Application
        #"pear-devs/pear/pear-desktop"
   			## Tools
   			"docker-slim"
   			"btop"
        "mise"
   			"nushell"
   			"openvpn"
   			"thefuck"
        "ripgrep"
        "zoxide"
   			"borders"
        "yazi"
   			"tree"
   			"fish"
   			"atuin"
   			"jq"
   			"yq"
   			"neovim"
   			"helix"
   			"go"
   			"chezmoi"
   			"docker-slim"
        "topgrade"
        "sops"
        "devcontainer"
        "pandoc"
  			## DevOps
        "ansible"
     		"hl"
  			"aiac"
   			"eksctl"
   			"hashicorp/tap/packer"
   			"opentofu"
   			"hashicorp/tap/terraform"
   			"terragrunt"
   			#"localstack"
   			"helm"
        "telnet"
        "krew"
   			"kubectl"
        "kubecolor"
   			"kdash-rs/kdash/kdash"
   			"k9s"
        "kind"
   			"kubecolor"
   			"kubie"
   			#"vcluster"
        "cilium-cli"
   			"trivy"
        "argocd"
   			"awscli"
   			#"awscli-local"
   			"aws-sam-cli"
        "spinframework/tap/spin"
   			## ZSH
   			"zsh"
   			"zsh-syntax-highlighting"
   			"zsh-autocomplete"
   			"zsh-autosuggestions"
   			"starship"
   			## AI
   			"claudish"
   			"gemini-cli"
   			## Learning
   			"exercism"
			];
			casks = [
			  ## AI
			  "claude-code"
			  ## Apps
			  #"xkey" temporary got error with brew
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
        ## DevTool
        #"termius"
        #"postman"
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

		fonts.packages = [
			pkgs.nerd-fonts.fira-mono
			pkgs.nerd-fonts.fira-code
		];
		# Necessary for using flakes on this system.
		nix.settings.experimental-features = [ "nix-command" "flakes" ];

		# Enable alternative shell support in nix-darwin.
		programs.zsh.enable = true;
		programs.fish.enable = true;

		# Set Git commit hash for darwin-version.
		system.configurationRevision = self.rev or self.dirtyRev or null;
		system.primaryUser = currentUser;
	 	# Used for backwards compatibility, please read the changelog before changing.
		# $ darwin-rebuild changelog
		system.stateVersion = 5;

		# The platform the configuration will be used on.
		nixpkgs.hostPlatform = "aarch64-darwin";
  };

  mkDarwinConfig = hostname: nix-darwin.lib.darwinSystem {
    modules = [
      configuration
      { networking.hostName = hostname; }
      nix-homebrew.darwinModules.nix-homebrew {
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = currentUser;
          autoMigrate = true;
        };
      }
    ];
  };

  # Auto-detect hostname or fallback to MT
  # To use auto-detection, run with: darwin-rebuild switch --flake . --impure
  currentHostname = let
    envHostname = builtins.getEnv "HOSTNAME";
  in if envHostname != "" then envHostname else "MT";

  in
  {
    darwinConfigurations = {
      # Fallback/Legacy name
      "MT" = mkDarwinConfig "MT";
    } // (if currentHostname != "MT" then {
      # Auto-detected configuration
      "${currentHostname}" = mkDarwinConfig currentHostname;
    } else {});
  };
}
