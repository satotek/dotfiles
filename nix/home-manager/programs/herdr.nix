{ config, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  # config.toml だけを可変 symlink で配置する。
  # herdr の ~/.config/herdr は runtime(socket/log/session.json)と config が同居するため、
  # ディレクトリ丸ごとではなく単一ファイルのみを対象にする。
  # mkOutOfStoreSymlink なので herdr 自身の書き換え(Settings / config reset-keys)も可能で、
  # キーバインド調整は repo の config.toml を編集して `herdr server reload-config` するだけで済む
  # (nix-switch 不要)。
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/herdr/config.toml";
}
