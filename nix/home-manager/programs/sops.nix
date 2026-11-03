{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretsDir = ../../../secrets;
  cloudflareSopsFile = "${secretsDir}/cloudflare.yaml";

  cloudflareSecret = {
    key = "cloudflare_infra_env";
    sopsFile = cloudflareSopsFile;
    target = "${config.home.homeDirectory}/.config/cloudflare/cloudflare-infra.env";
  };

  # OAuth のログインはエージェントがトークンを更新して書き戻すので、端末ごとに
  # ログインする。ここで配るのは静的な API キーだけ。
  agentsSopsFile = "${secretsDir}/agents.yaml";
  agentSecrets = [
    {
      key = "opencode_deepseek_api_key";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.config/opencode/secrets/deepseek.key";
    }
    {
      key = "opencode_google_api_key";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.config/opencode/secrets/google.key";
    }
    {
      key = "opencode_go_api_key";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.config/opencode/secrets/opencode-go.key";
    }
    {
      key = "commandcode_goat_api_key";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.config/opencode/secrets/commandcode.key";
    }
    # dsh は .credentials.yaml、プロセス環境、$DSH_HOME/.env の順に探す。.env なら
    # T3 から起動しても端末から起動しても読まれる。キーは opencode と共有し、
    # ローテート先を増やさないよう sops の同じキーから env 変数として追記する。
    {
      key = "opencode_go_api_key";
      envVar = "OPENCODE_GO_API_KEY";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.dsh/.env";
    }
    # 他のツールと共有するキーを env 変数として追記する。
    # 変数名は models.dev が CommandCode に割り当てているものに合わせる。
    {
      key = "commandcode_goat_api_key";
      envVar = "CMD_API_KEY";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.dsh/.env";
    }
  ];

  secrets = lib.optional pkgs.stdenv.hostPlatform.isDarwin cloudflareSecret ++ agentSecrets;

  installSecret =
    secret:
    if secret ? envVar then
      ''
        append_env_secret \
          ${lib.escapeShellArg (toString secret.sopsFile)} \
          ${lib.escapeShellArg secret.key} \
          ${lib.escapeShellArg secret.envVar} \
          ${lib.escapeShellArg secret.target}
      ''
    else
      ''
        decrypt_secret \
          ${lib.escapeShellArg (toString secret.sopsFile)} \
          ${lib.escapeShellArg secret.key} \
          ${lib.escapeShellArg secret.target}
      '';
in
{
  options.dotfiles.sops.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to decrypt dotfiles secrets with SOPS during Home Manager activation.";
  };

  # sops-nix requires an Age, GPG, or SSH key source even when the encrypted
  # files use only GCP KMS. Decrypt directly during activation so ADC is the
  # sole credential source.
  config = lib.mkIf config.dotfiles.sops.enable {
    home.activation.decryptSopsSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      decrypt_secret() {
        sops_file="$1"
        key="$2"
        target="$3"
        target_dir="$(${pkgs.coreutils}/bin/dirname "$target")"

        ${pkgs.coreutils}/bin/install -d -m 0700 "$target_dir"
        tmp="$(${pkgs.coreutils}/bin/mktemp "$target_dir/.sops.XXXXXX")"

        if ! ${pkgs.sops}/bin/sops \
          --decrypt \
          --extract "[\"$key\"]" \
          --output "$tmp" \
          "$sops_file"; then
          ${pkgs.coreutils}/bin/rm -f "$tmp"
          return 1
        fi

        ${pkgs.coreutils}/bin/chmod 0600 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      }

      append_env_secret() {
        sops_file="$1"
        key="$2"
        env_var="$3"
        target="$4"
        target_dir="$(${pkgs.coreutils}/bin/dirname "$target")"

        value="$(${pkgs.sops}/bin/sops \
          --decrypt \
          --extract "[\"$key\"]" \
          "$sops_file")" || return 1

        ${pkgs.coreutils}/bin/install -d -m 0700 "$target_dir"
        # 追記し続けると switch のたびに同じ変数が増えるので、既存の代入は
        # 落としてから書き直す。他の変数と手書きの行はそのまま残す。
        tmp="$(${pkgs.coreutils}/bin/mktemp "$target_dir/.sops.XXXXXX")"
        if [ -f "$target" ]; then
          ${pkgs.gnugrep}/bin/grep -v "^$env_var=" "$target" > "$tmp" || true
        fi
        # 既存ファイルが改行で終わっていないと追記した変数が前の行に繋がる。
        if [ -s "$tmp" ] && [ -n "$(${pkgs.coreutils}/bin/tail -c 1 "$tmp")" ]; then
          printf '\n' >> "$tmp"
        fi
        printf '%s=%s\n' "$env_var" "$value" >> "$tmp"
        ${pkgs.coreutils}/bin/chmod 0600 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      }

      umask 077
      ${lib.concatMapStringsSep "\n" installSecret secrets}
    '';
  };
}
