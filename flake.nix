{
  description = "Omnixiah NixOS";

  nixConfig = {
    extra-substituters = [
      "https://nix.tatikoma.dev"
      "https://microvm.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix.tatikoma.dev-1:+WItuSmHoqFJ82o9sQFNNl6D6amg6R1mLBToVuhpXIo="
      "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
    ];
  };

  inputs = {
    nixpkgs.url = "tarball+https://git.tatikoma.dev/omnixiah/nixpkgs/archive/omnixiah.tar.gz";
    xlibre = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/xlibre/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/nix/archive/omnixiah.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-23-11.follows = "";
        nixpkgs-regression.follows = "";
      };
    };

    disko = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/disko/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/home-manager/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dns = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/dns/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/sops-nix/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/deploy/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    nixos-anywhere = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/nixos-anywhere/archive/omnixiah.tar.gz";
      flake = false;
    };

    flake-parts.url = "tarball+https://git.tatikoma.dev/omnixiah/flake-parts/archive/omnixiah.tar.gz";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    flake-utils = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/flake-utils/archive/omnixiah.tar.gz";
      inputs.systems.follows = "systems";
    };
    systems.url = "tarball+https://git.tatikoma.dev/omnixiah/systems/archive/omnixiah.tar.gz";

    treefmt-nix = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/treefmt/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "tarball+https://git.tatikoma.dev/omnixiah/microvm/archive/omnixiah.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    let
      inherit (flake-parts.lib) mkFlake;
      inherit (nixpkgs.lib) filter hasSuffix;
    in
    mkFlake { inherit inputs; } {
      systems = filter (hasSuffix "-linux") (import inputs.systems);
      imports = [
        inputs.treefmt-nix.flakeModule
        ./flake/core.nix
        ./flake/development.nix
        ./flake/microvm.nix
      ];
    };
}
