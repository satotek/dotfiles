{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  # aerospace.toml だけを可変 symlink で配置する（karabiner / hunk と同じ方針）。
  # mkOutOfStoreSymlink なので、キーバインドの調整はファイル編集ですぐ反映される。
  # auto-reload-config を有効にしてあるので、初回の reload 以降は nix-switch 不要。
  xdg.configFile."aerospace/aerospace.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/aerospace/aerospace.toml";
}
