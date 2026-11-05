{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  mergeConfig = import ../lib/merge-config.nix { inherit pkgs lib; };

  # TUI が ~/.grok/config.toml へ書き戻すユーザー設定。
  # marketplace / privacy / hints はランタイム状態なので宣言しない。
  grokConfig = {
    cli.auto_update = false;

    # モデルと reasoning effort は固定せず、Grok の既定に任せる。

    features = {
      telemetry = false;
      lsp_tools = true;
      terminal_theme = true;
    };

    permission.deny = [
      "Bash(rm -rf *)"
      "Read(**/.env)"
      "Read(**/*.pem)"
    ];

    ui = {
      max_thoughts_width = 120;
      yolo = false;
      compact_mode = false;
      permission_mode = "auto";
      theme = "terminal";
      vim_mode = true;
      auto_dark_theme = "oscura-midnight";
      screen_mode = "fullscreen";
      show_timeline = false;
      page_flip_on_send = true;
      contextual_hints.undo = true;
    };
  };
in
{
  # Grok Build CLI。llm-agents.nix が提供する公式バイナリのパッケージを使う。
  home.packages = [ pkgs.llm-agents.grok ];

  # Grok は /theme や /settings で config.toml を書き換える。Nix store への
  # symlink は使わず、宣言した値だけを実ファイルへマージしてランタイム節を残す。
  # 以前の設定が書き戻したモデル固定もここで削除し、Grok の既定に戻す。
  home.activation.migrateGrokConfig = lib.hm.dag.entryBetween [ "grokConfig" ] [ "writeBoundary" ] ''
    output="${homeDir}/.grok/config.toml"
    if [[ -L "$output" ]]; then
      target="$(${pkgs.coreutils}/bin/readlink -f -- "$output")"
      if [[ -f "$target" ]]; then
        run ${pkgs.coreutils}/bin/rm -f "$output"
        run ${pkgs.coreutils}/bin/install -m 600 "$target" "$output"
      fi
    fi

    if [[ -f "$output" ]]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.jaq}/bin/jaq --from toml --to toml \
        'del(.models.default) | del(.ui.fork_secondary_model)' "$output" > "$tmp"; then
        run ${pkgs.coreutils}/bin/install -m 600 "$tmp" "$output"
      else
        warnEcho "Could not remove model pins from $output"
      fi
      rm -f "$tmp"
    fi
  '';

  home.activation.grokConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (mergeConfig {
    name = "grok-config-base.toml";
    path = "${homeDir}/.grok/config.toml";
    settings = grokConfig;
    format = "toml";
  });
}
