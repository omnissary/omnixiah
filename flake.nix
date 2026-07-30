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
    nixpkgs.url = "tarball+https://github.com/omnissary/nixpkgs/archive/corpix.tar.gz";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
        listToAttrs
        mapAttrs
        ;
      inherit (nixpkgs) lib;
      inherit (lib) mapAttrs' nameValuePair unique;
      inherit (flake-parts.lib) mkFlake;

      profileDefinitions = import ./profiles;
      testMetadata = import ./tests/metadata.nix;
      microvmLib = import ./lib/microvm.nix {
        inherit inputs self;
      };
      inherit (microvmLib) mkMicrovmProfile;

      profileNames = attrNames profileDefinitions;
      systems = unique (map (name: profileDefinitions.${name}.system) profileNames);

      profileNamesFor = system: filter (name: profileDefinitions.${name}.system == system) profileNames;

      profileMetadata = mapAttrs (_: profile: {
        inherit (profile) description system;
      }) profileDefinitions;

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
                pkgs = nixpkgs.legacyPackages.${system};
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
      inherit systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        lib = microvmLib // {
          profiles = profileMetadata;
          tests = testMetadata;
        };

        nixosModules = {
          base = ./modules/base.nix;
          firewall = ./modules/firewall.nix;
          nix = ./modules/nix.nix;
          qemu = ./modules/qemu.nix;
          serial = ./modules/serial.nix;
          sudo = ./modules/sudo.nix;
          systemd = ./modules/systemd.nix;
          tc = ./modules/tc.nix;
          timesync = ./modules/timesync.nix;
          update-diff = ./modules/update-diff.nix;
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
          inherit (pkgs) jq just;

          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          packages = profilePackages system;
          apps = profileApps system;
        in
        {
          _module.args.pkgs = pkgs;

          packages = packages // {
            default = packages.minimal;
          };

          apps = apps // {
            default = apps.minimal;
          };

          checks = profileChecks system // moduleChecks { inherit pkgs system; };

          devShells.default = pkgs.mkShellNoCC {
            packages = [
              just
              jq
            ]
            ++ [
              config.treefmt.build.wrapper
            ];
          };

          treefmt = {
            projectRootFile = ".git/config";

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
