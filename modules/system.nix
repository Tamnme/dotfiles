{ pkgs, currentUser, ... }:
{
  nix = {
    enable = false;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts.packages = [
    pkgs.nerd-fonts.fira-mono
    pkgs.nerd-fonts.fira-code
  ];

  programs.zsh.enable = true;
  programs.fish.enable = true;

  system.primaryUser = currentUser;
  # Backwards compat. Read changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
