let
  inherit (builtins)
    isAttrs
    isList
    isString
    mapAttrs
    throw
    ;

  raw = import ./packages.nix;

  command =
    name: value:
    if isList value && builtins.all isString value && value != [ ] then
      value
    else
      throw "package-update: ${name} must be a non-empty list of strings";

  package =
    name: value:
    if !isAttrs value then
      throw "package-update: ${name} must be an attribute set"
    else if !(value ? attrPath) || !isString value.attrPath || value.attrPath == "" then
      throw "package-update: ${name}.attrPath must be a non-empty string"
    else
      {
        inherit name;
        inherit (value) attrPath;
        format = map (command "${name}.format") (
          value.format or [
            [
              "nix"
              "fmt"
              "--accept-flake-config"
            ]
          ]
        );
        build = map (command "${name}.build") (value.build or [ ]);
        checks = map (command "${name}.checks") (value.checks or [ ]);
      }
      // (if value ? command then { command = command "${name}.command" value.command; } else { })
      // (
        if value ? versionCommand then
          { versionCommand = command "${name}.versionCommand" value.versionCommand; }
        else
          { }
      );
in
if !isAttrs raw then
  throw "package-update: packages.nix must return an attribute set"
else
  mapAttrs package raw
