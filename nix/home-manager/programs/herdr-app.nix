{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  dotfilesDir = "${homeDirectory}/dotfiles";
  appHome = "${config.xdg.configHome}/herdr-app";
  modSource = "${dotfilesDir}/.config/herdr-app/mods/tmux-prefix";
  package = pkgs.llm-agents.herdr-app;

  # keys.json はアプリも書き換える設定ファイルなので、宣言した分だけを jq で足す。
  # ctrl-q は tmux-prefix mod が単独で受け取るため、旧来の2打鍵コードは落とす。
  keysFilter = ''
    def without_chords: with_entries(select(.key | startswith("ctrl-q") | not));
    .global = ((.global // {}) | without_chords) + { "ctrl-q": "mod.open:tmux-prefix" }
    | .terminal = ((.terminal // {}) | without_chords) + { "ctrl-q": "mod.open:tmux-prefix" }
    | .["mod:tmux-prefix"] = ((.["mod:tmux-prefix"] // {}) + { "ctrl-q": "tmux-prefix.send-prefix" })
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # herdr-core と同じ llm-agents から入れ、core と app の版を flake.lock で揃える。
  # Nix 版はビルド時に HERDR_APP_RELEASE が無いので自己更新しない。
  home.packages = [ package ];

  # mod のフォルダにはアプリが gpui-kit.d.ts と jsconfig.json を書き出すので、
  # リポジトリへ symlink せずコピーで置く。
  home.activation.installHerdrAppMods = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    app_home="${appHome}"
    mod_dir="$app_home/mods/tmux-prefix"

    run ${pkgs.coreutils}/bin/mkdir -p "$mod_dir"
    run ${pkgs.coreutils}/bin/install -m644 ${modSource}/main.js "$mod_dir/main.js"
    run ${pkgs.coreutils}/bin/install -m644 ${modSource}/mod.json "$mod_dir/mod.json"

    # lazygit/btop は herdr core 側の prefix+alt+g/b に任せ、GUI の mod は畳む。
    for old in open-btop open-lazygit; do
      if [ -e "$app_home/mods/$old" ]; then
        run ${pkgs.coreutils}/bin/rm -rf "$app_home/mods/$old"
      fi
    done

    keys="$app_home/keys.json"
    if [ -e "$keys" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if run ${pkgs.jq}/bin/jq '${keysFilter}' "$keys" > "$tmp"; then
        run ${pkgs.coreutils}/bin/mv "$tmp" "$keys"
      else
        run ${pkgs.coreutils}/bin/rm -f "$tmp"
      fi
    fi
  '';

  # agent skill はアプリのバイナリが持っている (herdr-app --skill)。frontmatter が
  # 無いので、switch のたびに取り出して付けて配る。
  home.activation.installHerdrAppSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    app_bin="${lib.getExe package}"
    if skill="$("$app_bin" --skill 2>/dev/null)"; then
      version="$("$app_bin" --version 2>/dev/null)"
      version="''${version##* }"
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      {
        printf '%s\n' '---'
        printf '%s\n' 'name: herdr-app'
        printf '%s\n' 'description: "Drive the Herdr desktop window: spaces, tabs, panes, overlays, mods and screenshots through the herdr-app CLI. Use only when the user asks to inspect or change what the Herdr window shows; terminals and the agents inside them belong to herdr-core (hc)."'
        printf '%s\n' '---'
        printf '\n'
        printf '<!-- Generated from herdr-app %s at switch time. If herdr-app --version reports another version, run herdr-app --skill and follow that instead. -->\n\n' "$version"
        printf '%s\n' "$skill"
      } > "$tmp"
      for dest in "$HOME/.agents/skills/herdr-app/SKILL.md" "$HOME/.claude/skills/herdr-app/SKILL.md"; do
        if [ ! -f "$dest" ] || ! ${pkgs.coreutils}/bin/cmp -s "$tmp" "$dest"; then
          run ${pkgs.coreutils}/bin/install -Dm644 "$tmp" "$dest"
        fi
      done
      run ${pkgs.coreutils}/bin/rm -f "$tmp"
    fi
  '';
}
