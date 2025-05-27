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
    configuration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;
      # nix.configureBuildUsers = true; # Configure new nixbld User for MacOS Sequoia
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
				pkgs.mkalias
				pkgs.tmux
      ];
    homebrew.taps = [
      "gofireflyio/aiac"
      "spinframework/tap"
      "FelixKratz/formulae"
    ];
		homebrew = {
			enable = true;
			brews = [
   			# Tools
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
        "tabbyml/tabby/tabby"
  			# DevOps
  			"aiac"
   			"pulumi"
   			"opentofu"
   			"terraform"
   			"terragrunt"
   			"localstack"
   			"helm"
        "telnet"
        "krew"
   			"kubectl"
   			"kdash-rs/kdash/kdash"
   			"k9s"
        "kind"
   			"kubecolor"
   			"kubie"
        "cilium-cli"
   			"trivy"
        "argocd"
   			"awscli"
   			"awscli-local"
   			"aws-sam-cli"
        "spinframework/tap/spin"
   			# ZSH
   			"zsh"
   			"zsh-syntax-highlighting"
   			"zsh-autocomplete"
   			"zsh-autosuggestions"
   			"starship"
			];
			casks = [
        "flowvision"
        "hot"
        "only-switch"
        "pearcleaner"
				"music-decoy"
				"iina"
				"keka"
				"telegram"
        #DevTool
        "postman"
        "orbstack"
        "ghostty"
        "tabby"
        "warp"
				"aws-vault"
				"secretive"
				"flox"
				"zed"
        "docker"
        "github"
			];
			onActivation = {
				autoUpdate = false;
				cleanup = "zap";
				upgrade = false;
			};
		};

		fonts.packages = [
			pkgs.nerd-fonts.fira-mono
			pkgs.nerd-fonts.fira-code
		];
		# Necessary for using flakes on this system.
		nix.settings.experimental-features = "nix-command flakes";

		# Enable alternative shell support in nix-darwin.
		programs.zsh.enable = true;
		programs.fish.enable = true;

		# Set Git commit hash for darwin-version.
		system.configurationRevision = self.rev or self.dirtyRev or null;

		# Used for backwards compatibility, please read the changelog before changing.
		# $ darwin-rebuild changelog
		system.stateVersion = 5;

		# The platform the configuration will be used on.
		nixpkgs.hostPlatform = "aarch64-darwin";
  };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#apples-MacBook-Pro-2
    darwinConfigurations."zen8" = nix-darwin.lib.darwinSystem {
      modules = [
      	configuration
     		nix-homebrew.darwinModules.nix-homebrew {
         nix-homebrew = {
         		enable = true;
    				enableRosetta = true;
    				user = "apple";
    				autoMigrate = true;
         };
     		}
      ];
    };
  };
}
