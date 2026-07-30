{
  inputs,
  pkgs,
  self,
  system,
}:

let
  inherit (builtins) filter;
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    concatStringsSep
    elem
    hasInfix
    nixosSystem
    optionals
    ;

  cfg =
    (nixosSystem {
      inherit system;
      specialArgs = {
        inherit self;
      };
      modules = [
        self.nixosModules.base
        {
          networking.hostName = "defaults";
        }
      ];
    }).config;

  experimentalFeatures = cfg.nix.settings.experimental-features;
  requiredExperimentalFeatures = [
    "nix-command"
    "flakes"
  ];
  missingExperimentalFeatures = filter (
    feature: !(elem feature experimentalFeatures)
  ) requiredExperimentalFeatures;

  errors =
    optionals (!cfg.services.timesyncd.enable) [
      "services.timesyncd.enable is not true"
    ]
    ++
      optionals
        (
          cfg.services.timesyncd.servers != [
            "time.cloudflare.com"
            "time.google.com"
            "pool.ntp.org"
          ]
        )
        [
          "services.timesyncd.servers changed"
        ]
    ++ optionals (cfg.nix.package.outPath != pkgs.nixVersions.latest.outPath) [
      "nix.package is not pkgs.nixVersions.latest"
    ]
    ++ optionals (cfg.nix.settings.connect-timeout != 5) [
      "nix connect-timeout default changed"
    ]
    ++ map (feature: "${feature} experimental feature is missing") missingExperimentalFeatures
    ++ optionals (cfg.modules.boot.consoles != [ "ttyS0,115200" ]) [
      "default boot console changed"
    ]
    ++ optionals (cfg.security.sudo.wheelNeedsPassword != true) [
      "wheel sudo password default changed"
    ]
    ++ optionals (cfg.security.sudo.execWheelOnly != true) [
      "sudo exec wheel-only default changed"
    ]
    ++ optionals (!hasInfix "Defaults lecture = never" cfg.security.sudo.extraConfig) [
      "sudo lecture default changed"
    ]
    ++ optionals (cfg.systemd.settings.Manager.DefaultLimitCORE != "32M") [
      "systemd core limit default changed"
    ]
    ++ optionals (!hasInfix "SystemMaxUse=256M" cfg.services.journald.extraConfig) [
      "journald size default changed"
    ];
in

if errors != [ ] then
  throw "module defaults test failed:\n${concatStringsSep "\n" errors}"
else
  pkgs.writeText "omnixiah-module-defaults" ''
    ${concatStringsSep "\n" requiredExperimentalFeatures}
  ''
