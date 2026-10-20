{
  config,
  lib,
  pkgs,
  ...
}:
let
  sharedMcpServers = import ../data/mcp-servers.nix {
    inherit pkgs;
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
    # nixd / gopls / rust-analyzer / clangd / bash-language-server は Nix 側で
    # 入れてあるので、組み込み LSP を有効にしても追加取得は起きない。
    lsp = true;
    # キーは sops.nix が復号して置く。auth login で保存した credential があると
    # そちらが優先され、ここは黙って無視されるので、該当 provider は logout しておく。
    providers = lib.genAttrs [ "deepseek" "google" "opencode-go" ] (name: {
      settings.apiKey = "{file:~/.config/opencode/secrets/${name}.key}";
    });
    mcp.servers = lib.mapAttrs (_name: server: {
      type = "local";
      command = [ server.command ] ++ (server.args or [ ]);
    }) sharedMcpServers;
  };
  cliConfig = builtins.fromJSON (builtins.readFile ../../../.config/opencode/cli.json);
  cliConfigFile = pkgs.writers.writeJSON "opencode-cli.json" cliConfig;
  opencodeConfigFile = pkgs.writers.writeJSON "opencode.jsonc" opencodeConfig;
in
{
  # TUI プラグインは opencode.jsonc の plugins ではなく plugins/ 配下の探索で読まれる。
  xdg.configFile."opencode/plugins/usage-tui/tui.tsx".source =
    ../../../.config/opencode/plugins/usage-tui/tui.tsx;

  # astro / vue / yaml-ls などは実行時に GitHub からサーバーを落とす。Nix 管理外の
  # バイナリを増やさないよう止める。サーバーは起動元の環境を継承する。
  home.sessionVariables.OPENCODE_DISABLE_LSP_DOWNLOAD = "true";

  home.packages = [
    opencode2
    opencode
  ];

  # OpenCode は設定ファイルを書き戻すことがある。Nix store への symlink ではなく、
  # 宣言した値だけを実ファイルへマージし、アプリが書いた未宣言のキーは残す。
  home.activation.migrateOpenCodeFiles =
    lib.hm.dag.entryBetween
      [
        "configureOpenCodeCli"
        "configureOpenCodeConfig"
        "installHerdrAgentIntegrations"
      ]
      [ "writeBoundary" ]
      ''
        migrate_opencode_file() {
          local file="$1"
          [[ -L "$file" ]] || return 0

          local target
          target="$(${pkgs.coreutils}/bin/readlink -f -- "$file")"
          [[ -f "$target" ]] || return 0

          run ${pkgs.coreutils}/bin/rm -f "$file"
          run ${pkgs.coreutils}/bin/install -m 600 "$target" "$file"
        }

        migrate_opencode_file "${config.xdg.configHome}/opencode/opencode.jsonc"
        migrate_opencode_file "${config.xdg.configHome}/opencode/cli.json"
      '';

  # cli.json は Herdr がプラグイン登録を書き戻す。Nix 側はテーマだけをマージし、
  # Herdr が書いた plugins は残す。
  home.activation.configureOpenCodeCli =
    lib.hm.dag.entryAfter
      [
        "linkGeneration"
        "installHerdrAgentIntegrations"
      ]
      (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = "${config.xdg.configHome}/opencode/cli.json";
          staticSettings = cliConfigFile;
          mode = "600";
        }
      );

  # 自動更新と共有 MCP。providers や MCP の宣言だけを上書きする。
  home.activation.configureOpenCodeConfig =
    lib.hm.dag.entryAfter
      [
        "linkGeneration"
        "installHerdrAgentIntegrations"
      ]
      (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = "${config.xdg.configHome}/opencode/opencode.jsonc";
          staticSettings = opencodeConfigFile;
          mode = "600";
        }
      );

  # 上流のスキーマに追従できているかを確認する。取得に失敗しても switch は止めない。
  home.activation.validateOpenCodeConfig =
    lib.hm.dag.entryAfter
      [
        "configureOpenCodeCli"
        "configureOpenCodeConfig"
      ]
      ''
        validate_opencode_json() {
          local file="$1"
          [[ -f "$file" ]] || return 0

          local schema
          schema="$(${pkgs.jq}/bin/jq -r '.["$schema"] // empty' "$file")"
          [[ -n "$schema" ]] || return 0

          if ! ${pkgs.check-jsonschema}/bin/check-jsonschema --no-cache --schemafile "$schema" "$file" >/dev/null 2>&1; then
            warnEcho "OpenCode config did not validate against $schema: $file"
          fi
        }

        validate_opencode_json "${config.xdg.configHome}/opencode/opencode.jsonc"
        validate_opencode_json "${config.xdg.configHome}/opencode/cli.json"
      '';
}
