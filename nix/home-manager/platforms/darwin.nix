{ ... }:
{
  imports = [
    ../programs/karabiner.nix
    # sops(cloudflare secret)は Mac でしか使わないため darwin 限定 import。
    # azureuser 等の Linux ホストでは age 鍵を要求しない。
    ../programs/sops.nix
  ];
}
