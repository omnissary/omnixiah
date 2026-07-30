{
  lib,
  modulesPath,
  ...
}:

let
  inherit (lib) mkForce;
in

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot.initrd.availableKernelModules = [
    "sd_mod"
    "uas"
    "usbhid"
    "usb_storage"
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio"
    "ahci"
    "xhci_pci"
    "uhci_hcd"
    "ata_piix"
  ];

  boot.kernelParams = [
    "console=tty1"
  ];

  networking.usePredictableInterfaceNames = false;
  networking.dhcpcd.allowInterfaces = [ "eth*" ];

  systemd.services = {
    "autovt@tty1".enable = mkForce false;
    "autovt@".enable = mkForce true;
  };
}
