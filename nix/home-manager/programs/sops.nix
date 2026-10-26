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
    # T3 から起動しても端末から起動しても読まれる。
    {
      key = "dsh_env";
      sopsFile = agentsSopsFile;
      target = "${config.home.homeDirectory}/.dsh/.env";
    }
    # dsh_env の内容を保ったまま、他のツールと共有するキーを env 変数として追記する。
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
        # 既存ファイルが改行で終わっていないと追記した変数が前の行に繋がる。
        if [ -s "$target" ] && [ -n "$(${pkgs.coreutils}/bin/tail -c 1 "$target")" ]; then
          printf '\n' >> "$target"
        fi
        printf '%s=%s\n' "$env_var" "$value" >> "$target"
      }

      umask 077
      ${lib.concatMapStringsSep "\n" installSecret secrets}
    '';
  };
}
