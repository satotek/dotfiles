{ pkgs, lib, ... }:
let
  rtk = pkgs.llm-agents.rtk;

  # グローバル指示が `direnv exec . <cmd>` を求めるため、rtk はこの接頭辞の先を見ないと何も書き換えない。
  # 一致は文字列の前方一致なので、指示どおりの `.` 形だけを登録する。
  configText = ''
    [telemetry]
    enabled = false

    [hooks]
    transparent_prefixes = ["direnv exec ."]
  '';
in
{
  # フックが書き換えた後の rtk コマンドをエージェントが直接叩けるよう PATH にも入れる。
  home.packages = [ rtk ];

  xdg.configFile."rtk/config.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    text = configText;
  };

  # macOS の rtk は XDG ではなく Application Support を見る。
  home.file."Library/Application Support/rtk/config.toml" =
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      {
        text = configText;
      };

  # OpenCode はフックではなくプラグインで書き換える。rtk 同梱のものは v1 用で v2 では読めないので自作版を置く。
  # GUI から起動した OpenCode でも PATH に依存しないよう、rtk の store パスを焼き込む。
  xdg.configFile."opencode/plugins/rtk.js".source = pkgs.writeText "rtk.js" (
    builtins.replaceStrings [ ''execFile("rtk"'' ] [ ''execFile("${rtk}/bin/rtk"'' ] (
      builtins.readFile ../../../.config/opencode/plugins/rtk.js
    )
  );

  # omp は rtk 同梱の extension がそのまま使える。書き換え規則は `rtk rewrite` 側にあり、
  # extension は薄い委譲層なので、写さずに rtk 自身に生成させて rtk の更新に追従させる。
  # OpenCode と同じく PATH に依存しないよう store パスを焼き込む。
  home.file.".omp/agent/extensions/rtk.ts".source = pkgs.runCommand "rtk-omp-extension.ts" { } ''
    cd "$(mktemp -d)"
    HOME="$PWD" ${rtk}/bin/rtk init --agent omp > /dev/null
    substitute .omp/extensions/rtk.ts "$out" \
      --replace-fail 'pi.exec("rtk",' 'pi.exec("${rtk}/bin/rtk",'
  '';

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
