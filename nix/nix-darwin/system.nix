{ inputs, pkgs, self, username, ... }:
{
  imports = [ ./homebrew.nix ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.default
  ];

  # Determinate Nix manages the daemon and Nix installation itself, so
  # nix-darwin must not try to manage `nix.*` as well.
  nix.enable = false;

  # Determinate's nix-daemon merges /etc/nix/nix.custom.conf on top of the
  # installer-managed nix.conf. Use it to trust extra binary caches so that
  # flakes declaring nixConfig.extra-substituters (e.g. llm-agents.nix ->
  # cache.numtide.com for codex) actually substitute instead of building
  # from source.
  environment.etc."nix/nix.custom.conf".text = ''
    extra-substituters = https://cache.numtide.com
    extra-trusted-substituters = https://cache.numtide.com
    extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
  '';

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
