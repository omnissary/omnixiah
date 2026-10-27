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
      url = "github:microvm-nix/microvm.nix";
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
        filter
        intersectAttrs
        listToAttrs
        mapAttrs
        ;
      inherit (nixpkgs) lib;
      inherit (lib)
        composeManyExtensions
        concatStringsSep
        genAttrs
        mapAttrs'
        nameValuePair
        unique
        ;
      inherit (flake-parts.lib) mkFlake;

      profiles = {
        base = {
          description = "Shared defaults for all Omnixiah systems";
          module = {
            imports = [
              inputs.disko.nixosModules.default
              inputs.home-manager.nixosModules.default
              inputs.sops.nixosModules.default
              ./profiles/base.nix
            ];
            nixpkgs.overlays = [ overlay ];
          };
        };
        microvm = {
          description = "Insecure login defaults for disposable local MicroVMs";
          module = ./profiles/microvm.nix;
        };
        qemu = {
          description = "Hardware defaults for NixOS guests running under QEMU";
          module = ./profiles/qemu.nix;
        };
      };
      profileDefinitions = import ./profiles { inherit profiles; };
      testMetadata = import ./tests/metadata.nix;
      microvmLib = import ./lib/microvm.nix {
        inherit inputs self;
      };
      ownLib = microvmLib // {
        dns = inputs.dns.lib;
        profiles = profileMetadata;
        tests = testMetadata;
      };
      libCollisions = attrNames (intersectAttrs lib ownLib);
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
      inherit (microvmLib) mkMicrovmProfile;

      profileNames = attrNames profileDefinitions;
      profileSystems = unique (map (name: profileDefinitions.${name}.system) profileNames);
      packageSystems = import inputs.systems;

      profileNamesFor = system: filter (name: profileDefinitions.${name}.system == system) profileNames;

      profileMetadata = mapAttrs (_: profile: {
        inherit (profile) description system;
      }) profileDefinitions;

      pkgsFor = genAttrs packageSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        }
      );

      profilePackages =
        system:
        listToAttrs (
          map (name: {
            inherit name;
            value = self.nixosConfigurations.${name}.config.microvm.declaredRunner;
          }) (profileNamesFor system)
        );

      profileApps =
        system:
        mapAttrs (name: runner: {
          type = "app";
          program = "${runner}/bin/microvm-run";
          meta.description = profileDefinitions.${name}.description;
        }) (profilePackages system);

      profileChecks =
        system:
        listToAttrs (
          map (name: {
            name = "${name}-eval";
            value =
              let
                pkgs = pkgsFor.${system};
                config = self.nixosConfigurations.${name}.config;
              in
              pkgs.writeText "omnixiah-${name}-eval" config.system.build.toplevel.drvPath;
          }) (profileNamesFor system)
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
      systems = profileSystems;

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

        nixosConfigurations = mapAttrs (
          name: profile: mkMicrovmProfile (profile // { inherit name; })
        ) profileDefinitions;
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
          apps = profileApps system;
        in
        {
          _module.args.pkgs = pkgs;

          apps = apps // {
            default = apps.minimal;
          };

          checks =
            profileChecks system
            // moduleChecks { inherit pkgs system; }
            // {
              fork-sync = import ./maintenance/fork-sync/tests { inherit pkgs; };
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
