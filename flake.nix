{
  description = "nosuke's dotfiles managed with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      darwinUsername = "nosuke";
      darwinHostname = "nosuke-M5-MBP";
      darwinSystem = "aarch64-darwin";
      linuxNosukeX86_64 = import ./nix/hosts/linux/nosuke.nix {
        system = "x86_64-linux";
        hostname = "linux-x86_64";
      };
      linuxNosukeAarch64 = import ./nix/hosts/linux/nosuke.nix {
        system = "aarch64-linux";
        hostname = "linux-aarch64";
      };
      linuxAzureuserX86_64 = import ./nix/hosts/linux/azureuser.nix {
        system = "x86_64-linux";
        hostname = "linux-x86_64";
      };
      linuxAzureuserAarch64 = import ./nix/hosts/linux/azureuser.nix {
        system = "aarch64-linux";
        hostname = "linux-aarch64";
      };
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            inputs.llm-agents.overlays.default
          ];
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
              ./nix/home-manager/default.nix
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
          ./nix/hosts/darwin
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
                ./nix/home-manager/default.nix
                ./nix/home-manager/darwin.nix
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
          ./nix/home-manager/darwin.nix
        ];
      };

      homeConfigurations."nosuke@linux-x86_64" = mkHomeConfiguration linuxNosukeX86_64;

      homeConfigurations."nosuke@linux-aarch64" = mkHomeConfiguration linuxNosukeAarch64;

      homeConfigurations."azureuser@linux-x86_64" = mkHomeConfiguration linuxAzureuserX86_64;

      homeConfigurations."azureuser@linux-aarch64" = mkHomeConfiguration linuxAzureuserAarch64;
    };
}
