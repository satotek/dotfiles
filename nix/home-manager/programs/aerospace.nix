{ pkgs, ... }:
{
  # 本体は Nix パッケージ、起動は launchd、設定はリポジトリの toml から生成する。
  # 設定変更は保存では反映されず、nix-switch 時に reload-config が走る。
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    settings = builtins.fromTOML (builtins.readFile ../../../.config/aerospace/aerospace.toml);
  };

  # after-startup-command から borders を引く。
  home.packages = [ pkgs.jankyborders ];
}
