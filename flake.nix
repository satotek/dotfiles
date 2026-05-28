{
  description = "nosuke's dotfiles managed with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";
    agent-skills.inputs.home-manager.follows = "home-manager";

    vercel-agent-skills = {
      url = "github:vercel-labs/agent-skills";
      flake = false;
    };

    vercel-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };

    vercel-next-skills = {
      url = "github:vercel-labs/next-skills";
      flake = false;
    };

    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
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
      linuxNosukeWSL = import ./nix/hosts/linux/nosuke.nix {
        system = "x86_64-linux";
        hostname = "nosuke-windows";
      };
      linuxAzureuserX86_64 = import ./nix/hosts/linux/azureuser.nix {
        system = "x86_64-linux";
        hostname = "linux-x86_64";
      };
      linuxAzureuserAarch64 = import ./nix/hosts/linux/azureuser.nix {
        system = "aarch64-linux";
        hostname = "linux-aarch64";
      };
      linuxAzureuserGemAi = import ./nix/hosts/linux/azureuser.nix {
        system = "x86_64-linux";
        hostname = "gem-ai";
      };
      mkPkgs =
        system:
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
          modules = [
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

      darwinConfigurations.${darwinHostname} = import ./nix/hosts/darwin {
        inherit inputs self;
        username = darwinUsername;
        hostname = darwinHostname;
        system = darwinSystem;
      };

      homeConfigurations."${darwinUsername}@${darwinHostname}" = mkHomeConfiguration {
        system = darwinSystem;
        userName = darwinUsername;
        homeDirectory = "/Users/${darwinUsername}";
        hostname = darwinHostname;
        extraModules = [
          ./nix/home-manager/platforms/darwin.nix
          ./nix/home-manager/presets/base.nix
          ./nix/home-manager/presets/devtools.nix
          ./nix/home-manager/presets/webdevtools.nix
        ];
      };

      homeConfigurations."nosuke@linux-x86_64" = mkHomeConfiguration linuxNosukeX86_64;

      homeConfigurations."nosuke@nosuke-windows" = mkHomeConfiguration linuxNosukeWSL;

      homeConfigurations."nosuke@linux-aarch64" = mkHomeConfiguration linuxNosukeAarch64;

      homeConfigurations."azureuser@linux-x86_64" = mkHomeConfiguration linuxAzureuserX86_64;

      homeConfigurations."azureuser@linux-aarch64" = mkHomeConfiguration linuxAzureuserAarch64;

      homeConfigurations."azureuser@gem-ai" = mkHomeConfiguration linuxAzureuserGemAi;
    };
}
