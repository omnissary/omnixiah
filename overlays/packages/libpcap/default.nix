_self: super:
# rdma-core (CMakeLists.txt:234) asks FindPython for the Development
# component, which makes CMake 4.4 require the interpreter's pointer size to
# match CMAKE_SIZEOF_VOID_P. The x86_64 build python3 reports 8 bytes against
# 4 on armv7l, so it is rejected as "Wrong architecture" and configure fails.
# 64-bit targets such as aarch64 pass the check. RDMA capture is of no use on
# 32-bit ARM boards, so libpcap is built without it there.
super.lib.optionalAttrs super.stdenv.hostPlatform.isAarch32 {
  libpcap = super.libpcap.override { withRdma = false; };
}
