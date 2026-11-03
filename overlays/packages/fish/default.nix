_self: super:
# fish builds an xtask helper for the build platform that links pcre2 through
# pcre2-sys. When cross-compiling only the host pcre2 and the host-prefixed
# pkg-config are available, so the helper is pointed at the target libpcre2
# and fails to link. HOST_PKG_CONFIG is only read for build-platform crates,
# the target fish still links the target pcre2.
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
