{
  system,
  hostname ? system,
}:
{
  inherit system hostname;
  userName = "stko23";
  homeDirectory = "/home/stko23";
  # 業務用の WSL。AI エージェントは入れず、シークレットも復号しない。
  extraModules = [
    ../../home-manager/platforms/linux.nix
  ]
  ++ (import ../../home-manager/roles.nix).select [
    "base"
    "dev"
    "rust"
  ];
}
