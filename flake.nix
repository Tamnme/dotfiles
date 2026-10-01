{
  description = "MacOS nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Pinned: last rev before the brew 7.0.4 bump (#182), whose bin/brew shim lacks
    # HOMEBREW_ORIGINAL_BREW_FILE and breaks activation (nix-homebrew#187). Still has
    # the "# 🍺 Homebrew" README migration fix. Unpin once #187 is fixed.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew/09a921d0181146cf6163ec2cc1db7b6fd539a885";
    nix-homebrew.inputs.brew-src.follows = "brew-src";

    # Homebrew 5.1.7 introduced regression crashing on certain casks (e.g. iina, zed)
    # with "undefined method 'to_sym' for nil". Pin to 5.1.10.
    # See: https://github.com/Homebrew/brew/issues/17156
    brew-src = {
      url = "github:Homebrew/brew/5.1.10";
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
