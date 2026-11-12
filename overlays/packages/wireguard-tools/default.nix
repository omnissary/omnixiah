# Userspace counterpart of overlays/packages/linux: wg speaks the netlink
# contract the kernel patches define, so the two must be updated together.
_self: super: {
  wireguard-tools = super.wireguard-tools.overrideAttrs (_: {
    patchFlags = [ "-p2" ];
    patches = [
      # base amnezia support
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/ec8f4ff044aed600b3eede9828abff78d588bbea.patch
      ./base-amnezia-support.patch
      # S3,S4,I1-I5 support
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/13067d23d8b7cd4841d1a603c4456397fd3dec88.patch
      ./s3-s4-i1-i5-support.patch
      # awg3 uapi resync with the kernel tree
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/8d27021ae9d34d66346eef09542f842ec5630ecf.patch
      ./awg3-uapi-resync.patch
      # awg3 H1-H4 packed u64 and keepalive u32
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/6ed3ad73047b7c9c21dc214aeed209ff04fd9b3c.patch
      ./awg3-h1-h4-packed-u64-and-keepalive-u32.patch
      # awg3 device settings
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/91965661b8347e2f64080a5f3d33caff8e072eac.patch
      ./awg3-device-settings.patch
      # awg3 creating namespace reporting
      # https://git.tatikoma.dev/corpix/wireguard-tools/commit/8000a97dcca925f6b4dc13e3d2783039ed7b3894.patch
      ./awg3-creating-namespace-reporting.patch
    ];
  });
}
