{ config, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
in
{
  # hunk.dev (modem-dev/hunk): エージェント向けのターミナル diff ビューア。
  # nixpkgs には無いが llm-agents.nix オーバーレイが提供するため、
  # claude-code / codex 等と同じく pkgs.llm-agents.* から入れる（全ホスト共通・再現可能）。
  home.packages = [ pkgs.llm-agents.hunk ];

  # config.toml だけを可変 symlink で配置する（herdr と同じ方針）。
  # hunk は daemon/session のランタイム状態を ~/.config/hunk に書く可能性があるため、
  # ディレクトリ丸ごとではなく単一ファイルのみを対象にする。
  # mkOutOfStoreSymlink なのでアプリ内のテーマ選択(t キー)による書き換えも repo 側に反映され、
  # カラースキーム変更は config.toml を編集するだけで済む（nix-switch 不要）。
  xdg.configFile."hunk/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/hunk/config.toml";
}
