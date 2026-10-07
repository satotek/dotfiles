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
  # Orca の SSH トンネル待受は gem-ai だけ。他の azureuser ホストには置かない。
  ++ (if hostname == "gem-ai" then [ ../../home-manager/programs/orca.nix ] else [ ]);
}
