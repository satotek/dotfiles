{
  description = "nosuke's dotfiles managed with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      username = "nosuke";
      hostname = "nosuke-M5-MBP";
      system = "aarch64-darwin";
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      formatter.${system} = (mkPkgs system).nixfmt-rfc-style;

      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs self username hostname;
        };
        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          {
            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
            };

            home-manager.backupFileExtension = "pre-home-manager";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs self username hostname;
            };
            home-manager.users.${username} = {
              imports = [
                ./modules/home/common.nix
                ./modules/home/darwin.nix
              ];

              home.username = username;
              home.homeDirectory = "/Users/${username}";
              home.stateVersion = "25.05";

              programs.home-manager.enable = true;
            };
          }
        ];
      };

      homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = {
          inherit inputs self username hostname;
        };
        modules = [
          ./modules/home/common.nix
          ./modules/home/darwin.nix
          {
            home.username = username;
            home.homeDirectory = "/Users/${username}";
            home.stateVersion = "25.05";

            programs.home-manager.enable = true;
          }
        ];
      };
    };
}
