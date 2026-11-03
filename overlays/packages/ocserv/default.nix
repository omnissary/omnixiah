_self: super:
# Cross builds only: ipcalc and protoc-c run at build time but are only listed
# in buildInputs, so no build-machine copies are on PATH. The /proc/self/exe
# configure check can not run when cross compiling.
super.lib.optionalAttrs (super.stdenv.buildPlatform != super.stdenv.hostPlatform) {
  ocserv = super.ocserv.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [
      super.buildPackages.ipcalc
      super.buildPackages.protobufc
    ];
    configureFlags = (old.configureFlags or [ ]) ++ [ "ac_cv_file__proc_self_exe=yes" ];
  });
}
