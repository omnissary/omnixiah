{
  inputs,
  pkgs,
  self,
  system,
}:

{
  allwinner = import ./modules/allwinner.nix {
    inherit pkgs self;
  };
  coverage = import ./coverage.nix {
    inherit pkgs self system;
  };
  dns = import ./lib/dns.nix {
    inherit pkgs self;
  };
  base = import ./modules/base.nix {
    inherit pkgs;
  };
  defaults = import ./modules/defaults.nix {
    inherit
      inputs
      pkgs
      self
      system
      ;
  };
  overlay-order = import ./modules/overlay-order.nix {
    inherit pkgs self system;
  };
  fail2ban = import ./modules/fail2ban.nix {
    inherit
      inputs
      pkgs
      self
      system
      ;
  };
  firewall = import ./modules/firewall.nix {
    inherit pkgs;
  };
  grub = import ./modules/grub.nix {
    inherit pkgs;
  };
  rockchip = import ./modules/rockchip.nix {
    inherit
      inputs
      pkgs
      self
      ;
  };
  tc = import ./modules/tc.nix {
    inherit pkgs;
  };
  wireguard-amnezia = import ./modules/wireguard-amnezia.nix {
    inherit pkgs;
  };
  wireguard = import ./modules/wireguard.nix {
    inherit
      inputs
      pkgs
      self
      system
      ;
  };
}
