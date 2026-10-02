{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  context7ApiKeyFile = "${homeDirectory}/.config/context7/api-key";
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit context7ApiKeyFile;
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
  };
  opencode2 = pkgs.llm-agents.opencode2;

  # llm-agents は v1 の opencode と共存させるため実行ファイル名を opencode2 にする。
  # この dotfiles は v1 を入れないので、今使っているコマンド名 opencode も出す。
  opencode = pkgs.runCommand "opencode" { } ''
    mkdir -p $out/bin
    ln -s ${opencode2}/bin/opencode2 $out/bin/opencode
  '';

  # update はグローバル設定でのみ効く。command は OpenCode の argv 配列に畳む。
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    update = "disable";
    mcp.servers = lib.mapAttrs (_name: server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    }) sharedMcpServers;
  };
in
{
  home.packages = [
    opencode2
    opencode
  ];

  # テーマだけの設定。サーバの合言葉とセッション状態は同じディレクトリに残す。
  xdg.configFile."opencode/cli.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/opencode/cli.json";

  # 自動更新と共有 MCP。ホストごとに中身が変わるので、テーマファイルとは別に生成する。
  xdg.configFile."opencode/opencode.jsonc".source =
    pkgs.writers.writeJSON "opencode.jsonc" opencodeConfig;
}
