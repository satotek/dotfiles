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

  # Nix 本体とデーモン設定はシステム層で管理する。GC は既存の nh ジョブに集約する。
  nix = {
    enable = true;
    package = pkgs.nix;
    gc.automatic = false;
    optimise.automatic = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://satotek.cachix.org"
      ];
      extra-trusted-substituters = [
        "https://cache.numtide.com"
        "https://satotek.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "satotek.cachix.org-1:/2yz7ZHPnRzW91UqChW6XmRSX2Tq0NrNPjKsIUppRFA="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    # クラムシェルなどで Touch ID が使えないときは Apple Watch で承認する。
    watchIdAuth = true;
    # ターミナルマルチプレクサの中からでも Touch ID の認証ダイアログを利用できるようにする。
    reattach = true;
  };

  # 再生キーで Music.app が起動しないよう、キーを拾う rcd をユーザーの launchd で
  # 無効にする。次回ログインから効く。
  system.activationScripts.postActivation.text = ''
    /bin/launchctl disable "gui/$(/usr/bin/id -u -- ${username})/com.apple.rcd"
    # 外出先から接続できるよう、電源接続中だけ自動スリープを防ぐ。
    /usr/bin/pmset -c sleep 0
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
