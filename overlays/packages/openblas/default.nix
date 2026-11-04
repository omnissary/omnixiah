_self: super:
# The ARMV7 kernels use d16-d31, which a vfpv3-d16 toolchain (nixpkgs armv7l
# default) rejects; the ARMV6 kernels stay within d0-d15.
super.lib.optionalAttrs (super.stdenv.hostPlatform.gcc.fpu or null == "vfpv3-d16") {
  openblas = super.openblas.override { target = "ARMV6"; };
}
