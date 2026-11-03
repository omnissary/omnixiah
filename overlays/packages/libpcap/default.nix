_self: super:
super.lib.optionalAttrs super.stdenv.hostPlatform.isAarch32 {
  libpcap = super.libpcap.override { withRdma = false; };
}
