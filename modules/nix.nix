{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    optional
    optionals
    versionAtLeast
    versionOlder
    versions
    ;

  nixVersion = versions.majorMinor config.nix.package.version;

  experimentalFeatures = [
    "nix-command"
    "flakes"
    "auto-allocate-uids"
    "cgroups"
    "fetch-closure"
    "recursive-nix"
    "configurable-impure-env"
  ]
  ++ optional (versionOlder nixVersion "2.22") "repl-flake"
  ++ optionals (versionAtLeast nixVersion "2.28") [
    "ca-derivations"
    "impure-derivations"
  ]
  ++ optionals (versionAtLeast nixVersion "2.29") [
    "blake3-hashes"
  ];
in

{
  nix.package = mkDefault pkgs.nixVersions.latest;
  nix.channel.enable = mkDefault false;

  nix.settings = {
    connect-timeout = mkDefault 5;
    fallback = mkDefault true;
    experimental-features = mkDefault experimentalFeatures;
    auto-allocate-uids = mkDefault true;
    system-features = mkDefault [ "uid-range" ];
    log-lines = mkDefault 25;
    max-free = mkDefault (3000 * 1024 * 1024);
    min-free = mkDefault (512 * 1024 * 1024);
    builders-use-substitutes = mkDefault true;
    trusted-users = mkDefault [ "@wheel" ];
  };

  nix.optimise.automatic = mkDefault (!config.boot.isContainer);

  nix.daemonCPUSchedPolicy = mkDefault "batch";
  nix.daemonIOSchedClass = mkDefault "idle";
  nix.daemonIOSchedPriority = mkDefault 7;

  systemd.services.nix-gc.serviceConfig = {
    CPUSchedulingPolicy = mkDefault "batch";
    IOSchedulingClass = mkDefault "idle";
    IOSchedulingPriority = mkDefault 7;
  };

  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = mkDefault 250;

  nix.gc = {
    automatic = mkDefault true;
    dates = mkDefault [ "daily" ];
    options = mkDefault "--delete-older-than 30d";
  };

  systemd.services.nix-generation-gc = mkIf config.nix.gc.automatic {
    serviceConfig.Type = "oneshot";
    path = [
      config.nix.package
      pkgs.gawk
    ];
    script = ''
      set -eu

      profile=/nix/var/nix/profiles/system
      keep=5

      gens="$(nix-env -p "$profile" --list-generations | awk '{ print $1 }')"
      count="$(printf '%s\n' "$gens" | sed '/^$/d' | wc -l)"

      if [ "$count" -le "$keep" ]; then
        exit 0
      fi

      delete="$(
        printf '%s\n' "$gens" \
          | sed '/^$/d' \
          | head -n -"$keep" \
          | tr '\n' ' '
      )"

      if [ -n "$delete" ]; then
        nix-env -p "$profile" --delete-generations $delete
      fi
    '';
  };

  systemd.timers.nix-generation-gc = mkIf config.nix.gc.automatic {
    timerConfig.OnCalendar = "daily";
    wantedBy = [ "timers.target" ];
    partOf = [ "nix-generation-gc.service" ];
  };
}
