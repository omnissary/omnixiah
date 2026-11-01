{
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkDefault
    mkOption
    types
    ;
  inherit (pkgs)
    coreutils
    iproute2
    iputils
    procps
    util-linux
    vim
    ;
in

{
  imports = attrValues (import ../modules { inherit lib; });

  options.omnixiah.base = mkOption {
    type = types.bool;
    readOnly = true;
    default = true;
    description = "Whether this configuration was built from the Omnixiah base profile.";
  };

  config = {
    system.stateVersion = mkDefault "25.11";

    networking = {
      useNetworkd = mkDefault true;
      firewall.enable = mkDefault true;
    };

    systemd.network.enable = mkDefault true;

    services.openssh.enable = mkDefault false;

    users.mutableUsers = mkDefault false;

    documentation = {
      doc.enable = mkDefault false;
      info.enable = mkDefault false;
      man.enable = mkDefault false;
      nixos.enable = mkDefault false;
    };

    programs.command-not-found.enable = mkDefault false;

    environment.systemPackages = [
      coreutils
      iproute2
      iputils
      procps
      util-linux
      vim
    ];
  };
}
