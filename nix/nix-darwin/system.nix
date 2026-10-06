{
  inputs,
  pkgs,
  self,
  username,
  ...
}:
{
  imports = [
    ./fonts.nix
    ./homebrew.nix
    ./macos-defaults.nix
    ./nix-cleanup.nix
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    self.overlays.default
  ];

  # Determinate Nix manages the daemon and Nix installation itself, so
  # nix-darwin must not try to manage `nix.*` as well. Trusted binary caches
  # (cache.numtide.com for codex etc.) are injected once at install time via
  # the Determinate installer's --extra-conf; see README.
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    # クラムシェルなどで Touch ID が使えないときは Apple Watch で承認する。
    watchIdAuth = true;
    # tmux などの中からでも Touch ID の認証ダイアログを利用できるようにする。
    reattach = true;
  };

  # 再生キーで Music.app が起動しないよう、キーを拾う rcd をユーザーの launchd で
  # 無効にする。次回ログインから効く。
  system.activationScripts.postActivation.text = ''
    /bin/launchctl disable "gui/$(/usr/bin/id -u -- ${username})/com.apple.rcd"
  '';

  programs.zsh.enable = true;
  # Home Manager 側の zshrc が compinit をキャッシュ付きで遅延実行するので、
  # /etc/zshrc の同期 compinit（毎起動フルスキャン）とプロンプト初期化は無効化する
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.enableBashCompletion = false;
  programs.zsh.promptInit = "";

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = username;
  system.stateVersion = 6;

  users.users.${username}.shell = pkgs.zsh;
}
