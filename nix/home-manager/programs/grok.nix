{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  tomlFormat = pkgs.formats.toml { };

  # TUI が ~/.grok/config.toml へ書き戻すユーザー設定。
  # marketplace / privacy / hints はランタイム状態なので宣言しない。
  grokConfig = {
    cli.auto_update = false;

    models.default = "grok-4.6";

    features = {
      telemetry = false;
      lsp_tools = true;
    };

    permission.deny = [
      "Bash(rm -rf *)"
      "Read(**/.env)"
      "Read(**/*.pem)"
    ];

    ui = {
      max_thoughts_width = 120;
      fork_secondary_model = "grok-4.6";
      yolo = false;
      compact_mode = false;
      permission_mode = "auto";
      theme = "oscura-midnight";
      vim_mode = true;
      auto_dark_theme = "oscura-midnight";
      screen_mode = "fullscreen";
      show_timeline = false;
      page_flip_on_send = true;
      contextual_hints.undo = true;
    };
  };
  baseConfigFile = tomlFormat.generate "grok-config-base.toml" grokConfig;
in
{
  # Grok Build CLI。llm-agents.nix が提供する公式バイナリのパッケージを使う。
  home.packages = [ pkgs.llm-agents.grok ];

  # Grok は /theme や /settings で config.toml を書き換えるため、store symlink
  # にはしない。宣言した設定を通常ファイルとして書き、ランタイム節は残す。
  home.activation.generateGrokConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    grok_dir="${homeDir}/.grok"
    output="$grok_dir/config.toml"
    runtime_file="$(mktemp)"

    mkdir -p "$grok_dir"
    if [ -L "$output" ]; then
      rm -f "$output"
    fi

    if [ -f "$output" ]; then
      ${pkgs.gawk}/bin/awk '
        /^\[/ {
          keep = ($0 ~ /^\[\[?marketplace/ || $0 ~ /^\[privacy/ || $0 ~ /^\[hints/)
        }
        keep { print }
      ' "$output" > "$runtime_file"
    fi

    cp -f ${lib.escapeShellArg baseConfigFile} "$output"
    chmod 644 "$output"

    if [ -s "$runtime_file" ]; then
      printf '\n' >> "$output"
      cat "$runtime_file" >> "$output"
    fi
    rm -f "$runtime_file"
  '';
}
