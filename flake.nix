{
  description = "MacOS nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
            enableRosetta = true;
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
