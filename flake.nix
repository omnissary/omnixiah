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
    nix.url = "tarball+https://git.tatikoma.dev/omnixiah/nix/archive/omnixiah.tar.gz";

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
      inputs.nixos-anywhere.url = "tarball+https://git.tatikoma.dev/omnixiah/nixos-anywhere/archive/835e722926f784a07383e949c093c2339e5a7438.tar.gz";
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
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    let
      inherit (builtins)
        attrNames
        intersectAttrs
        ;
      inherit (nixpkgs) lib;
      inherit (lib)
        composeManyExtensions
        concatStringsSep
        filter
        genAttrs
        hasSuffix
        mapAttrs'
        nameValuePair
        ;
      inherit (flake-parts.lib) mkFlake;

      baseProfile = {
        imports = [
          inputs.disko.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.sops.nixosModules.default
          ./profiles/base.nix
        ];
        nixpkgs.overlays = [ overlay ];
      };
      profiles = {
        base = baseProfile;
        debug = ./profiles/debug.nix;
        microvm = ./profiles/microvm.nix;
        qemu = ./profiles/qemu.nix;
      };
      testMetadata = import ./tests/metadata.nix;
      ownLib = {
        dns = inputs.dns.lib;
        nixosSystem =
          args: lib.nixosSystem (args // { modules = [ profiles.base ] ++ (args.modules or [ ]); });
        tests = testMetadata;
      };
      libCollisions = attrNames (removeAttrs (intersectAttrs lib ownLib) [ "nixosSystem" ]);
      flakeLib =
        if libCollisions == [ ] then
          lib // ownLib
        else
          throw "Omnixiah lib collides with nixpkgs lib: ${concatStringsSep ", " libCollisions}";

      namedOverlays = {
        omnixiah = import ./overlays { inherit inputs; };
      };
      enabledOverlayNames = [ "omnixiah" ];
      overlay = composeManyExtensions (map (name: namedOverlays.${name}) enabledOverlayNames);
      overlays = namedOverlays // {
        default = overlay;
      };

      packageSystems = import inputs.systems;
      microvmSystems = filter (hasSuffix "-linux") packageSystems;

      pkgsFor = genAttrs packageSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        }
      );
      microvmConfigurations = genAttrs microvmSystems (
        system:
        ownLib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self; };
          modules = [
            inputs.microvm.nixosModules.microvm
            profiles.microvm
            {
              networking.hostName = lib.mkDefault "omnixiah-microvm";
            }
          ];
        }
      );

      moduleChecks =
        {
          pkgs,
          system,
        }:
        let
          moduleTests = import ./tests {
            inherit
              inputs
              pkgs
              self
              system
              ;
          };
        in
        mapAttrs' (name: test: nameValuePair "module-${name}" test) moduleTests;
    in
    mkFlake { inherit inputs; } {
      systems = microvmSystems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        inherit overlays profiles;

        lib = flakeLib;
        pkgs = pkgsFor;

        modules = {
          fail2ban = ./modules/fail2ban.nix;
          firewall = ./modules/firewall.nix;
          nix = ./modules/nix.nix;
          serial = ./modules/serial.nix;
          sudo = ./modules/sudo.nix;
          systemd = ./modules/systemd.nix;
          tc = ./modules/tc.nix;
          timesync = ./modules/timesync.nix;
          update-diff = ./modules/update-diff.nix;
          wireguard = ./modules/wireguard.nix;
        };

        nixosConfigurations = mapAttrs' (
          system: configuration: nameValuePair "microvm-${system}" configuration
        ) microvmConfigurations;
      };

      perSystem =
        {
          config,
          system,
          ...
        }:
        let
          inherit (pkgs)
            git
            jq
            just
            ;

          pkgs = pkgsFor.${system};
          configuration = microvmConfigurations.${system};
          runner = configuration.config.microvm.declaredRunner;
          microvmApp = {
            type = "app";
            program = "${runner}/bin/microvm-run";
            meta.description = "Run an Omnixiah MicroVM";
          };
        in
        {
          _module.args.pkgs = pkgs;

          apps = {
            default = microvmApp;
            microvm = microvmApp;
          };

          packages = {
            default = runner;
            microvm = runner;
          };

          checks = moduleChecks { inherit pkgs system; } // {
            fork-sync = import ./maintenance/fork-sync/tests { inherit pkgs; };
            microvm-eval = pkgs.writeText "omnixiah-microvm-eval" configuration.config.system.build.toplevel.drvPath;
            package-update = import ./maintenance/package-update/tests { inherit pkgs; };
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = [
              git
              just
              jq
            ]
            ++ [
              config.treefmt.build.wrapper
            ];
          };

          treefmt = {
            projectRootFile = "flake.nix";

            programs.shellcheck.enable = true;

            programs.deadnix.enable = true;
            programs.deadnix.priority = 1;
            programs.deadnix.no-lambda-arg = true;

            programs.statix.enable = true;
            programs.statix.priority = 2;

            programs.nixfmt.enable = true;
            programs.nixfmt.priority = 3;
          };
        };
    };
}
