{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    # 拡張と keyring は配布側に同梱し、実行時のインストールを避ける。
    inputs.azure-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.google-cloud-sdk
  ];

  # az devops login が書く PAT と、t3 が読む環境変数ファイル。どちらも秘密。
  home.activation.restrictAzureDevopsPat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    chmod_if_present() {
      if [ -f "$1" ]; then
        run ${pkgs.coreutils}/bin/chmod 0600 "$1"
      fi
    }
    chmod_if_present ${lib.escapeShellArg "${config.home.homeDirectory}/.azure/azuredevops/personalAccessTokens"}
    chmod_if_present ${lib.escapeShellArg "${config.xdg.configHome}/azure-devops/env"}
  '';
}
