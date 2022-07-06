{
  description = "FahrplanDatenGarten NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    leona-nixfiles = {
      url = "git+https://cyberchaos.dev/leona/nixfiles";
      flake = false;
    };
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
   }@inputs:
    let
      defaultModules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        {
          imports = [
            ./modules/nftables
            ./modules/sops
            (import (inputs.leona-nixfiles + "/users/leona/importable.nix"))
          ];
          nix.nixPath = nixpkgs.lib.mkDefault [
            "nixpkgs=${nixpkgs}"
            "home-manager=${inputs.home-manager}"
          ];
          _module.args.inputs = inputs;
        }
      ];

      hosts = {
        web = {
          nixosSystem = {
            system = "x86_64-linux";
            modules = defaultModules ++ [
              ./hosts/web
            ];
          };
        };
      };
    in
    inputs.flake-utils.lib.eachDefaultSystem(system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.sops
            pkgs.colmena
          ];
        };
      }
    ) // {
      nixosConfigurations = (nixpkgs.lib.mapAttrs (name: config: (nixpkgs.lib.nixosSystem rec {
        system = config.nixosSystem.system;
        modules = config.nixosSystem.modules;
      })) hosts);
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
        };
      } // builtins.mapAttrs (host: config: let
        nixosConfig = self.nixosConfigurations."${host}";
      in {
        nixpkgs.system = nixosConfig.config.nixpkgs.system;
        imports = nixosConfig._module.args.modules;
        deployment = {
          buildOnTarget = true;
#          targetHost = nixosConfig.config.networking.hostName + "." + nixosConfig.config.networking.domain;
          targetHost = "2a01:4f8:242:155f:4000::b8b";
          targetUser = null;
        };
      }) (hosts);

  };
}
