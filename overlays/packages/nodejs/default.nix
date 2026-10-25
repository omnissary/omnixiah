final: prev:
let
  inherit (prev.lib) hasPrefix;

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
in
{
  nodejs-slim_24 = skipZfsFilenameTests prev.nodejs-slim_24;
  nodejs_24 = prev.callPackage (prev.path + "/pkgs/development/web/nodejs/symlink.nix") {
    nodejs-slim = final.nodejs-slim_24;
  };

  nodejs-slim = final.nodejs-slim_24;
  nodejs = final.nodejs_24;
}
