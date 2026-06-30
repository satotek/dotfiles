{ inputs, pkgs, self, username, ... }:
{
  imports = [ ./homebrew.nix ./macos-defaults.nix ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.default
  ];

  # Determinate Nix manages the daemon and Nix installation itself, so
  # nix-darwin must not try to manage `nix.*` as well. Trusted binary caches
  # (cache.numtide.com for codex etc.) are injected once at install time via
  # the Determinate installer's --extra-conf; see README.
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  fonts.packages = with pkgs; [
    hackgen-nf-font
  ];

  programs.zsh.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username}.shell = pkgs.zsh;
}
