{
  description = "FahrplanDatenGarten NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ccc-nixlib = {
      url = "gitlab:cyberchaoscreatures/nixlib/main?host=cyberchaos.dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena/main";
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
    fdg-app = {
      url = "github:FahrplanDatenGarten/fahrplandatengarten/poetry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    suxin = inputs.ccc-nixlib.suxinSystem {
      modules = [
        ./nodes.nix
      ];
      specialArgs = { inherit inputs; };
    };
    overlays = {
      colmena = inputs.colmena.overlay;
      fdg = inputs.fdg-app.overlay;
    };
    inherit (inputs.self.suxin.config) nixosConfigurations colmenaHive;
  } // inputs.flake-utils.lib.eachDefaultSystem(system:
    let pkgs = inputs.nixpkgs.legacyPackages.${system}; in
    {
      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.sops
          pkgs.colmena
        ];
      };
    }
  );
}
