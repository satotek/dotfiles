{ pkgs, lib, ... }:
let
  rtk = pkgs.llm-agents.rtk;
in
{
  # フックが書き換えた後の rtk コマンドをエージェントが直接叩けるよう PATH にも入れる。
  home.packages = [ rtk ];

  xdg.configFile."rtk/config.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    text = ''
      [telemetry]
      enabled = false
    '';
  };

  # macOS の rtk は XDG ではなく Application Support を見る。
  home.file."Library/Application Support/rtk/config.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      [telemetry]
      enabled = false
    '';
  };

  # Bash の出力を圧縮して読ませ、コンテキストを節約する。
  # rtk は permissionDecision を返さないので、書き換え後のコマンドにも通常の権限判定が掛かる。
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${rtk}/bin/rtk hook claude";
        }
      ];
    }
  ];
}
