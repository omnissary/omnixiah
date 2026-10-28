{
  inputs,
  lib,
  self,
  ...
}:

let
  inherit (lib)
    mapAttrs'
    nameValuePair
    ;

  mkModuleChecks =
    {
      pkgs,
      system,
    }:
    let
      moduleTests = import ../tests {
        inherit
          inputs
          pkgs
          self
          system
          ;
      };
    in
    mapAttrs' (name: test: nameValuePair "module-${name}" test) moduleTests;
in
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      inherit (pkgs)
        git
        jq
        just
        ;
    in
    {
      checks = mkModuleChecks { inherit pkgs system; } // {
        fork-sync = import ../maintenance/fork-sync/tests { inherit pkgs; };
        package-update = import ../maintenance/package-update/tests { inherit pkgs; };
      };

      devShells.default = pkgs.mkShellNoCC {
        packages = [
          git
          just
          jq
          config.treefmt.build.wrapper
        ];
      };

      treefmt = {
        projectRootFile = "flake.nix";

        programs.shellcheck.enable = true;

        programs.deadnix.enable = true;
        programs.deadnix.priority = 1;
        programs.deadnix.no-lambda-arg = true;

        programs.statix.enable = true;
        programs.statix.priority = 2;

        programs.nixfmt.enable = true;
        programs.nixfmt.priority = 3;
      };
    };
}
