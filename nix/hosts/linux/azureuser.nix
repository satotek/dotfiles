{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "azureuser";
  homeDirectory = "/home/azureuser";
  extraModules = [
    ../../home-manager/platforms/linux.nix
  ]
  ++ (import ../../home-manager/roles.nix).select [
    "base"
    "dev"
    "ai"
    "secrets"
  ]
  # T3 Code のサーバーと、そこへ届く tailnet の口は gem-ai だけ。他の azureuser ホストには置かない。
  ++ (
    if hostname == "gem-ai" then
      [
        ../../home-manager/programs/t3code.nix
        ../../home-manager/programs/tailscale.nix
        ../../home-manager/programs/zsh-history-check.nix
      ]
    else
      [ ]
  );
}
