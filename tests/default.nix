{
  inputs,
  pkgs,
  self,
  system,
}:

let
  testing = import "${inputs.nixpkgs}/nixos/lib/testing-python.nix" {
    inherit pkgs system;
  };
in

{
  base = import ./modules/base.nix {
    inherit self testing;
  };
  defaults = import ./modules/defaults.nix {
    inherit
      inputs
      pkgs
      self
      system
      ;
  };
  firewall = import ./modules/firewall.nix {
    inherit pkgs self testing;
  };
  tc = import ./modules/tc.nix {
    inherit self testing;
  };
}
