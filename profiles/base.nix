{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
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
  imports = [
    ../modules/fail2ban.nix
    ../modules/firewall.nix
    ../modules/nix.nix
    ../modules/serial.nix
    ../modules/sudo.nix
    ../modules/systemd.nix
    ../modules/tc.nix
    ../modules/timesync.nix
    ../modules/update-diff.nix
    ../modules/wireguard.nix
  ];

  system.stateVersion = mkDefault "25.11";

  nixpkgs.config.allowUnfree = mkDefault true;

  modules.boot.consoles = mkDefault [ "ttyS0,115200" ];

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
}
