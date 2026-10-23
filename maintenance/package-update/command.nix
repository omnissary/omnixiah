let
  root = builtins.getEnv "PACKAGE_UPDATE_ROOT";
  system = builtins.getEnv "PACKAGE_UPDATE_SYSTEM";
  attrPath = builtins.getEnv "PACKAGE_UPDATE_ATTR_PATH";
  flake = builtins.getFlake "path:${root}";
  pkgs = flake.pkgs.${system};
  inherit (pkgs) lib;
  package = lib.attrByPath (lib.splitString "." attrPath) null pkgs;
  updateScript =
    if package == null then
      throw "package-update: package ${attrPath} does not exist"
    else
      package.updateScript or (throw "package-update: package ${attrPath} has no passthru.updateScript");
  command = map toString (lib.toList (updateScript.command or updateScript));
in
pkgs.writeShellApplication {
  name = "omnixiah-package-update";
  text = ''
    export UPDATE_NIX_NAME=${lib.escapeShellArg package.name}
    export UPDATE_NIX_PNAME=${lib.escapeShellArg (lib.getName package)}
    export UPDATE_NIX_OLD_VERSION=${lib.escapeShellArg (lib.getVersion package)}
    export UPDATE_NIX_ATTR_PATH=${lib.escapeShellArg "pkgs.${system}.${attrPath}"}
    exec ${lib.escapeShellArgs command}
  '';
}
