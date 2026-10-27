{ lib }:

let
  inherit (builtins)
    attrNames
    listToAttrs
    readDir
    ;
  inherit (lib)
    filterAttrs
    hasSuffix
    nameValuePair
    removeSuffix
    ;

  isModule = name: type: type == "regular" && name != "default.nix" && hasSuffix ".nix" name;
in

listToAttrs (
  map (name: nameValuePair (removeSuffix ".nix" name) (./. + "/${name}")) (
    attrNames (filterAttrs isModule (readDir ./.))
  )
)
