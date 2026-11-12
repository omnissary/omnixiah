# AmneziaWG kernel implementation. Must be updated together with
# overlays/packages/wireguard-tools, which speaks the netlink contract these
# patches define.
_self: super: {
  linuxPackages = super.linuxPackages.extend (
    _: kernelPrev: {
      kernel = kernelPrev.kernel.override (old: {
        kernelPatches = old.kernelPatches ++ [
          {
            name = "amnezia wireguard extension";
            # https://git.tatikoma.dev/omnixiah/linux/commit/0a7add86b1bbf888cf1ecf9c6c5224ce5f4f2400.patch
            patch = ./amnezia-wireguard-extension.patch;
          }
          {
            name = "netlink peer notifications extension";
            # https://git.tatikoma.dev/omnixiah/linux/commit/4e00c40e93a701ef8335e39b425bc5eac0ed5d9a.patch
            patch = ./netlink-peer-notifications-extension.patch;
          }
          {
            name = "creating net nsid reporting extension";
            # https://git.tatikoma.dev/omnixiah/linux/commit/29c8ccffdcfd67339541297716eaa11288336810.patch
            patch = ./creating-net-nsid-reporting-extension.patch;
          }
          {
            name = "add ranged magic headers and per-packet junk sizes";
            # https://git.tatikoma.dev/omnixiah/linux/commit/2c3784865bd134625f428699a7850b143ab86c58.patch
            patch = ./ranged-magic-headers-and-per-packet-junk-sizes.patch;
          }
          {
            name = "add configurable CPS packet generation";
            # https://git.tatikoma.dev/omnixiah/linux/commit/d4eac4ad083aa882198041f00ad6e925cc5132cf.patch
            patch = ./configurable-cps-packet-generation.patch;
          }
          {
            name = "harden CPS descriptor configuration";
            # https://git.tatikoma.dev/omnixiah/linux/commit/f9b6a697e2032e289d2c29847c45fb9003c75ec7.patch
            patch = ./harden-cps-descriptor-configuration.patch;
          }
          {
            name = "expose per-peer inner traffic counters";
            # https://git.tatikoma.dev/omnixiah/linux/commit/71aa477f5ea7937276aaf70fd4e1687b717e1ecf.patch
            patch = ./per-peer-inner-traffic-counters.patch;
          }
          {
            name = "amneziawg 3.0 and 3.1 support";
            # https://git.tatikoma.dev/omnixiah/linux/compare/765842550b5b99db529d43df471ee84d74da7cf8...7727732d33bd4f4200b2893c2ead32eac5742d91.diff
            patch = ./amneziawg-3.0-and-3.1-support.diff;
          }
          {
            name = "amneziawg naming, correctness fixes and selftests";
            # https://git.tatikoma.dev/omnixiah/linux/compare/7727732d33bd4f4200b2893c2ead32eac5742d91...cfdedaaa0b0867366e8045771363a6b727caa9f3.diff
            patch = ./amneziawg-naming-correctness-fixes-and-selftests.diff;
          }
          {
            name = "defer single-peer cleanup outside configuration locks";
            # https://git.tatikoma.dev/omnixiah/linux/commit/81f124d51cb761c49261283e820fe8dad3e90de9.patch
            patch = ./defer-single-peer-cleanup-outside-configuration-locks.patch;
          }
        ];
      });
    }
  );
}
