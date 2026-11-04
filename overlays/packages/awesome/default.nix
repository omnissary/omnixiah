_self: super: {
  awesome =
    (super.awesome.override {
      gtk3Support = true;
    }).overrideAttrs
      (
        old:
        # Cross builds only: fonts.conf is read by the doc build on the build
        # machine, but nixpkgs takes it from the target package set, which
        # cross-builds ghostscript for its fonts.
        super.lib.optionalAttrs (super.stdenv.buildPlatform != super.stdenv.hostPlatform) {
          env = old.env // {
            FONTCONFIG_FILE = toString super.pkgsBuildBuild.texFunctions.fontsConf;
          };
        }
      );
}
