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
  firewall = import ./modules/firewall.nix {
    inherit pkgs self testing;
  };
}
