final: prev:
let
  inherit (builtins)
    attrNames
    filter
    listToAttrs
    match
    readDir
    ;
  inherit (prev.lib)
    concatMap
    hasPrefix
    nameValuePair
    removePrefix
    removeSuffix
    ;

  nodejsPath = prev.path + "/pkgs/development/web/nodejs";

  skipZfsFilenameTests =
    package:
    package.overrideAttrs (old: {
      checkFlags = map (
        flag:
        if hasPrefix "CI_SKIP_TESTS=" flag then
          "${flag},test-fileurltopathbuffer,test-fs-readdir-ucs2"
        else
          flag
      ) (old.checkFlags or [ ]);
    });

  nodejsVersions = map (name: removeSuffix ".nix" (removePrefix "v" name)) (
    filter (name: match "v[0-9]+\\.nix" name != null) (attrNames (readDir nodejsPath))
  );
  nodejsSlimNames = map (version: "nodejs-slim_${version}") nodejsVersions;
  versionedNodejs = listToAttrs (
    concatMap (
      slimName:
      let
        version = removePrefix "nodejs-slim_" slimName;
      in
      [
        (nameValuePair slimName (skipZfsFilenameTests prev.${slimName}))
        (nameValuePair "nodejs_${version}" (
          prev.callPackage (nodejsPath + "/symlink.nix") {
            nodejs-slim = final.${slimName};
          }
        ))
      ]
    ) nodejsSlimNames
  );
in
versionedNodejs
// {
  nodejs-slim = final.nodejs-slim_24;
  nodejs = final.nodejs_24;
}
