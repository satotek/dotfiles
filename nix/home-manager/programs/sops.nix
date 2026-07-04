{ config, inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/cloudflare.yaml;

    secrets.cloudflare-infra-env = {
      key = "cloudflare_infra_env";
      path = "${config.home.homeDirectory}/.config/cloudflare/cloudflare-infra.env";
    };
  };
}
