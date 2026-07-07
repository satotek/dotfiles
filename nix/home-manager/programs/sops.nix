{
  config,
  inputs,
  lib,
  ...
}:
let
  secretsDir = ../../../secrets;
  context7SopsFile = "${secretsDir}/context7.yaml";
  hasContext7SopsFile = builtins.pathExists context7SopsFile;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/cloudflare.yaml;

    secrets = {
      cloudflare-infra-env = {
        key = "cloudflare_infra_env";
        path = "${config.home.homeDirectory}/.config/cloudflare/cloudflare-infra.env";
      };
    } // lib.optionalAttrs hasContext7SopsFile {
      "context7-api-key" = {
        sopsFile = context7SopsFile;
        key = "context7_api_key";
        path = "${config.home.homeDirectory}/.config/context7/api-key";
      };
    };
  };
}
