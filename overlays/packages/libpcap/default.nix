_self: super:
# rdma-core fails to configure when cross-compiled to 32-bit ARM: CMake
# FindPython rejects the 64-bit build python3 as "Wrong architecture".
super.lib.optionalAttrs super.stdenv.hostPlatform.isAarch32 {
  libpcap = super.libpcap.override { withRdma = false; };
}
