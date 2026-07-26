{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  managedSettingsFile = pkgs.writeText "antigravity-cli-managed-settings.json" (
    builtins.toJSON {
      # Auto-approve tool calls globally. This is equivalent to selecting
      # "always-proceed" for Tool Permission in /settings.
      toolPermission = "always-proceed";
    }
  );
in
{
  home.packages = [ pkgs.llm-agents.antigravity-cli ];

  # AGY stores global preferences and mutable runtime state such as
  # trustedWorkspaces in the same JSON file. Keep the file writable and merge
  # only the settings owned by Nix instead of replacing the whole file with a
  # read-only Nix store symlink.
  home.activation.generateAntigravityCliSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="${homeDir}/.gemini/antigravity-cli"
    settings_file="$settings_dir/settings.json"

    mkdir -p "$settings_dir"
    merged_settings="$(mktemp "$settings_dir/.settings.json.XXXXXX")"

    if [ -f "$settings_file" ]; then
      if ${pkgs.jq}/bin/jq empty "$settings_file" >/dev/null 2>&1; then
        ${pkgs.jq}/bin/jq --slurp '.[0] * .[1]' \
          "$settings_file" \
          ${lib.escapeShellArg managedSettingsFile} > "$merged_settings"
      else
        rm -f "$merged_settings"
        echo "ERROR: refusing to overwrite invalid AGY settings: $settings_file" >&2
        exit 1
      fi
    else
      cp ${lib.escapeShellArg managedSettingsFile} "$merged_settings"
    fi

    chmod 600 "$merged_settings"
    mv -f "$merged_settings" "$settings_file"
  '';
}
