{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretsDir = ../../../secrets;
  cloudflareSopsFile = "${secretsDir}/cloudflare.yaml";
  context7SopsFile = "${secretsDir}/context7.yaml";
  hasContext7SopsFile = builtins.pathExists context7SopsFile;

  cloudflareSecret = {
    key = "cloudflare_infra_env";
    sopsFile = cloudflareSopsFile;
    target = "${config.home.homeDirectory}/.config/cloudflare/cloudflare-infra.env";
  };

  context7Secret = {
    key = "context7_api_key";
    sopsFile = context7SopsFile;
    target = "${config.home.homeDirectory}/.config/context7/api-key";
  };

  secrets =
    lib.optional pkgs.stdenv.isDarwin cloudflareSecret
    ++ lib.optional hasContext7SopsFile context7Secret;

  installSecret = secret: ''
    decrypt_secret \
      ${lib.escapeShellArg (toString secret.sopsFile)} \
      ${lib.escapeShellArg secret.key} \
      ${lib.escapeShellArg secret.target}
  '';
in
{
  # sops-nix requires an Age, GPG, or SSH key source even when the encrypted
  # files use only GCP KMS. Decrypt directly during activation so ADC is the
  # sole credential source.
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

    umask 077
    ${lib.concatMapStringsSep "\n" installSecret secrets}
  '';
}
