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
      darwinUsername = "nosuke";
      darwinHostname = "nosuke-M5-MBP";
      darwinSystem = "aarch64-darwin";
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHomeConfiguration =
        {
          system,
          userName,
          homeDirectory,
          hostname ? null,
          extraModules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs self hostname;
            username = userName;
          };
          modules =
            [
              ./modules/home/common.nix
              {
                home.username = userName;
                home.homeDirectory = homeDirectory;
                home.stateVersion = "25.05";

                programs.home-manager.enable = true;
              }
            ]
            ++ extraModules;
        };
    in
    {
      formatter.${darwinSystem} = (mkPkgs darwinSystem).nixfmt-rfc-style;

      darwinConfigurations.${darwinHostname} = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = {
          inherit inputs self;
          username = darwinUsername;
          hostname = darwinHostname;
        };
        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
          {
            users.users.${darwinUsername} = {
              name = darwinUsername;
              home = "/Users/${darwinUsername}";
            };

            home-manager.backupFileExtension = "pre-home-manager";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs self;
              username = darwinUsername;
              hostname = darwinHostname;
            };
            home-manager.users.${darwinUsername} = {
              imports = [
                ./modules/home/common.nix
                ./modules/home/darwin.nix
              ];

              home.username = darwinUsername;
              home.homeDirectory = "/Users/${darwinUsername}";
              home.stateVersion = "25.05";

              programs.home-manager.enable = true;
            };
          }
        ];
      };

      homeConfigurations."${darwinUsername}@${darwinHostname}" = mkHomeConfiguration {
        system = darwinSystem;
        userName = darwinUsername;
        homeDirectory = "/Users/${darwinUsername}";
        hostname = darwinHostname;
        extraModules = [
          ./modules/home/darwin.nix
        ];
      };

      homeConfigurations."nosuke@linux-x86_64" = mkHomeConfiguration {
        system = "x86_64-linux";
        userName = "nosuke";
        homeDirectory = "/home/nosuke";
        hostname = "linux-x86_64";
        extraModules = [
          ./modules/home/linux.nix
        ];
      };

      homeConfigurations."nosuke@linux-aarch64" = mkHomeConfiguration {
        system = "aarch64-linux";
        userName = "nosuke";
        homeDirectory = "/home/nosuke";
        hostname = "linux-aarch64";
        extraModules = [
          ./modules/home/linux.nix
        ];
      };

      homeConfigurations."azureuser@linux-x86_64" = mkHomeConfiguration {
        system = "x86_64-linux";
        userName = "azureuser";
        homeDirectory = "/home/azureuser";
        hostname = "linux-x86_64";
        extraModules = [
          ./modules/home/linux.nix
        ];
      };

      homeConfigurations."azureuser@linux-aarch64" = mkHomeConfiguration {
        system = "aarch64-linux";
        userName = "azureuser";
        homeDirectory = "/home/azureuser";
        hostname = "linux-aarch64";
        extraModules = [
          ./modules/home/linux.nix
        ];
      };
    };
}
