_final: prev:
let
  patchFileinfo =
    php:
    let
      fileinfo = php.extensions.fileinfo.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # UTF-8-only filesystems reject the deliberately invalid path with EILSEQ.
          substituteInPlace ext/fileinfo/tests/bug68996.phpt \
            --replace-fail "Failed to open stream: No such file or directory" \
            "Failed to open stream: %s"
        '';
      });

      patched = php.withExtensions (
        { enabled, ... }:
        map (extension: if extension.extensionName == "fileinfo" then fileinfo else extension) enabled
      );
    in
    patched
    // {
      extensions = patched.extensions // {
        inherit fileinfo;
      };
    };
in
{
  php83 = patchFileinfo prev.php83;
  php84 = patchFileinfo prev.php84;
  php85 = patchFileinfo prev.php85;
}
