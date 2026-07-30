{
  lib,
  pkgs,
  self,
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
    ./firewall.nix
  ];

  system.stateVersion = mkDefault "25.11";
  system.configurationRevision = self.rev or self.dirtyRev or null;

  nixpkgs.config.allowUnfree = mkDefault true;

  boot.kernelParams = [
    "console=ttyS0"
  ];

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
