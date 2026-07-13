{ ... }:
{
  imports = [
    ../programs/karabiner.nix
    # sops(cloudflare secret)は Mac でしか使わないため darwin 限定 import。
    ../programs/sops.nix
  ];
}
