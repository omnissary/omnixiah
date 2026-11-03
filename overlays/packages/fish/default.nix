_self: super:
# Cross builds only: fish compiles a build-machine helper (xtask) that links
# pcre2, but pkg-config hands it the target's libpcre2 and linking fails.
# Give the build side its own pkg-config and pcre2.
super.lib.optionalAttrs (super.stdenv.buildPlatform != super.stdenv.hostPlatform) {
  fish = super.fish.overrideAttrs (old: {
    depsBuildBuild = (old.depsBuildBuild or [ ]) ++ [
      super.pkgsBuildBuild.pkg-config
      super.pkgsBuildBuild.pcre2
    ];
    env = (old.env or { }) // {
      HOST_PKG_CONFIG = "pkg-config";
    };
  });
}
