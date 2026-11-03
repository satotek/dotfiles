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
    "rust"
    "ai"
    "secrets"
  ]
  # T3 Code のサーバーと、そこへ届く tailnet の口は gem-ai だけ。
  # CLI と settings.json は ai preset で全ホストに入る。
  ++ (
    if hostname == "gem-ai" then
      [
        ../../home-manager/programs/t3code-server.nix
        ../../home-manager/programs/tailscale.nix
        ../../home-manager/programs/zsh-history-check.nix
      ]
    else
      [ ]
  );
}
