_self: super:
# Cross builds only: configure probes Xft with a bare pkg-config, which is not
# on PATH under cross, so tk falls back to core X fonts (tkUnixFont.c), which
# no longer compiles against glibc 2.43+ const strchr.
super.lib.optionalAttrs (super.stdenv.buildPlatform != super.stdenv.hostPlatform) {
  tk = super.tk.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace unix/configure \
        --replace-fail '`pkg-config --' '`$PKG_CONFIG --'
    '';
  });
}
