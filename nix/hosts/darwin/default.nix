{
  inputs,
  self,
  username,
  hostname,
  system,
}:
inputs.nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit
      inputs
      self
      username
      hostname
      ;
  };

  modules = [
    ../../nix-darwin/system.nix
    inputs.home-manager.darwinModules.home-manager
    {
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };

      home-manager.backupFileExtension = "pre-home-manager";
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {
        inherit
          inputs
          self
          username
          hostname
          ;
      };
      home-manager.users.${username} = {
        imports = [
          ../../home-manager/default.nix
          ../../home-manager/platforms/darwin.nix
          ../../home-manager/presets/base.nix
          ../../home-manager/presets/devtools.nix
          ../../home-manager/presets/webdevtools.nix
        ];

        home.username = username;
        home.homeDirectory = "/Users/${username}";
        home.stateVersion = "25.05";

        programs.home-manager.enable = true;
      };
    }
  ];
}
