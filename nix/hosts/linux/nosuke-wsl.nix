{
  system,
  hostname ? system,
}:
# role の重複を避け、共通の Linux 構成に WSL 固有の連携を追加する。
let
  base = import ./nosuke.nix { inherit system hostname; };
in
base
// {
  extraModules = base.extraModules ++ [
    ../../home-manager/programs/git-wsl.nix
  ];
}
