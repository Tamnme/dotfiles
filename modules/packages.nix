{ pkgs, ... }:
{
  # System-wide Nix packages. Search names:
  # $ nix-env -qaP | grep <name>
  environment.systemPackages = [
    pkgs.mkalias
    pkgs.tmux
    pkgs.devenv
  ];
}
