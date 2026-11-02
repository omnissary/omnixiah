{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkDefault
    mkOption
    optional
    types
    ;
  inherit (pkgs)
    coreutils
    efibootmgr
    iproute2
    iputils
    procps
    util-linux
    vim
    ;
  inherit (config.boot.loader)
    grub
    limine
    refind
    systemd-boot
    ;

  efi =
    (grub.enable && grub.efiSupport)
    || (limine.enable && limine.efiSupport)
    || refind.enable
    || systemd-boot.enable;
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

    system.nixos = {
      distroId = mkDefault "omnixiah";
      distroName = mkDefault "Omnixiah NixOS";
      vendorId = mkDefault "omnixiah";
      vendorName = mkDefault "Omnixiah";
    };

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

    boot.loader.grub.efiRemovableBootOrder.enable = mkDefault (
      grub.enable && grub.efiSupport && grub.efiInstallAsRemovable
    );

    environment.systemPackages = [
      coreutils
      iproute2
      iputils
      procps
      util-linux
      vim
    ]
    ++ optional efi efibootmgr;
  };
}
