{
  description = "MacOS nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Release branch must match the locked nixpkgs release (checkRelease). 26.05 passes
    # brew 7's --force-cleanup; the old LnL7 rev passed --cleanup, which brew 7 removed.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.brew-src.follows = "brew-src";

    # Keep brew-src in step with nix-homebrew's shim (modules/brew.tail.sh is a copy of
    # upstream bin/brew). Mismatch = nix-homebrew#187: brew <=6.0.x fetches
    # HOMEBREW_ORIGINAL_BREW_FILE, which the 7.0.4+ shim no longer exports.
    # Needs >=7.0 for casks using preflight_steps (e.g. gcloud-cli).
    brew-src = {
      url = "github:Homebrew/brew/7.0.9";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, brew-src }:
  let
    # Auto-detect current user (handles sudo). Fallback "tamnm".
    currentUser = let
      sudoUser = builtins.getEnv "SUDO_USER";
      envUser = builtins.getEnv "USER";
    in if sudoUser != "" then sudoUser
       else if envUser != "" && envUser != "root" then envUser
       else "tamnm";

    # Auto-detect hostname. Fallback "MT".
    # Run: HOSTNAME=$(hostname -s) darwin-rebuild switch --flake . --impure
    currentHostname = let
      envHostname = builtins.getEnv "HOSTNAME";
    in if envHostname != "" then envHostname else "MT";

    # Pick host file or fallback to default.nix for unknown hosts.
    hostModule = hostname:
      let path = ./hosts + "/${hostname}.nix";
      in if builtins.pathExists path then path else ./hosts/default.nix;

    mkDarwinConfig = hostname: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit currentUser; };
      modules = [
        ./modules/system.nix
        ./modules/packages.nix
        ./modules/homebrew-base.nix
        (hostModule hostname)
        { networking.hostName = hostname; }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # ponytail: Intel prefix (/usr/local) is empty — no x86 formulae/casks.
            # Rosetta setup was just emitting a warning for an unused prefix. Flip
            # back to true (and run softwareupdate --install-rosetta) if you ever
            # need an Intel-only cask.
            enableRosetta = false;
            user = currentUser;
            autoMigrate = true;
          };
        }
      ];
    };
  in
  {
    darwinConfigurations = {
      # Legacy fallback name.
      "MT" = mkDarwinConfig "MT";
    } // (if currentHostname != "MT" then {
      "${currentHostname}" = mkDarwinConfig currentHostname;
    } else {});
  };
}
