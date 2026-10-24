_final: prev:
let
  skipZfsUnicodeTests =
    package:
    package.overrideAttrs (old: {
      preInstallCheck = (old.preInstallCheck or "") + ''
        # These tests make assumptions about NFC/NFD pathname handling which
        # do not hold on ZFS datasets with Unicode normalization enabled.
        disable_test t0050-filesystem
        disable_test t7527-builtin-fsmonitor 'Unicode nfc'
      '';
    });
in
{
  git = skipZfsUnicodeTests prev.git;
  gitFull = skipZfsUnicodeTests prev.gitFull;
  gitMinimal = skipZfsUnicodeTests prev.gitMinimal;
  gitSVN = skipZfsUnicodeTests prev.gitSVN;
}
