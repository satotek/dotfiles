{ pkgs, self, username, ... }:
{
  imports = [ ./homebrew.nix ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix manages the daemon and Nix installation itself, so
  # nix-darwin must not try to manage `nix.*` as well.
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  programs.zsh.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username}.shell = pkgs.zsh;
}
