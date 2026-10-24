# Userspace counterpart of overlays/packages/linux: wg speaks the netlink
# contract the kernel patches define, so the two must be updated together.
_self: super: {
  wireguard-tools = super.wireguard-tools.overrideAttrs (_: {
    patchFlags = [ "-p2" ];
    patches = [
      # base amnezia support
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/wireguard-tools/commit/ec8f4ff044aed600b3eede9828abff78d588bbea.patch";
        hash = "sha256-PsGsLb71hlLXURL/s1I1clxacCKwaJfl/x5fQWbyZu4=";
      })
      # S3,S4,I1-I5 support
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/wireguard-tools/commit/13067d23d8b7cd4841d1a603c4456397fd3dec88.patch";
        hash = "sha256-B/a4awTSx95opo+c2ft7BpnunmsbLnNPfcFZ4FuLcko=";
      })
      # awg3 uapi resync with the kernel tree
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/wireguard-tools/commit/8d27021ae9d34d66346eef09542f842ec5630ecf.patch";
        hash = "sha256-GMHxeymssU+OKcY2uJkPNUVz/5X75r2JKE8RzP/WuKI=";
      })
      # awg3 H1-H4 packed u64 and keepalive u32
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/wireguard-tools/commit/6ed3ad73047b7c9c21dc214aeed209ff04fd9b3c.patch";
        hash = "sha256-cvFhqloihgQb8VwqJLmj05g9FTPsuFVveabfyO2Ne9g=";
      })
      # awg3 device settings
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/wireguard-tools/commit/91965661b8347e2f64080a5f3d33caff8e072eac.patch";
        hash = "sha256-La1b4DsLS+xT1hP1DoDn5ZOqjh/sA+EGHrdw+IOdAhc=";
      })
    ];
  });
}
