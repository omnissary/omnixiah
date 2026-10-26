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
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/0a7add86b1bbf888cf1ecf9c6c5224ce5f4f2400.patch";
              hash = "sha256-8XEJWH6UT+Uv1HAyl92BQ1j/BissU/jfTJrRpMZ4oz4=";
            };
          }
          {
            name = "netlink peer notifications extension";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/4e00c40e93a701ef8335e39b425bc5eac0ed5d9a.patch";
              hash = "sha256-jPl/q741SYmP0w6I1evOLciSlhlh8sqH0LGBLpVfa7I=";
            };
          }
          {
            name = "creating net nsid reporting extension";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/29c8ccffdcfd67339541297716eaa11288336810.patch";
              hash = "sha256-XqbpffjtQ+p9zaLQCVkxw9LHqlmoIA2mYeI20RJqJ44=";
            };
          }
          {
            name = "add ranged magic headers and per-packet junk sizes";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/2c3784865bd134625f428699a7850b143ab86c58.patch";
              hash = "sha256-32F6Xkx+p/7HT7R5M0tEq4l+7KvFgkkiiGnb2ISA5E0=";
            };
          }
          {
            name = "add configurable CPS packet generation";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/d4eac4ad083aa882198041f00ad6e925cc5132cf.patch";
              hash = "sha256-dD4hGi5kr8M680wC4PijT1pA3eT5foZHS9tZJEGr2C8=";
            };
          }
          {
            name = "harden CPS descriptor configuration";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/f9b6a697e2032e289d2c29847c45fb9003c75ec7.patch";
              hash = "sha256-i9J7Vj6M5fSMN5qYxd5zCHjOMZEnz0xWYtijurJCym8=";
            };
          }
          {
            name = "expose per-peer inner traffic counters";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/71aa477f5ea7937276aaf70fd4e1687b717e1ecf.patch";
              hash = "sha256-EBEDYljafLP4+AVrgGN1NCMZUdn0rNO5gsyl5ktMHD4=";
            };
          }
          {
            name = "amneziawg 3.0 and 3.1 support";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/compare/765842550b5b99db529d43df471ee84d74da7cf8...7727732d33bd4f4200b2893c2ead32eac5742d91.diff";
              hash = "sha256-6ny/m5lqL/G/x2LXkC+Bh2XLb7eCoDQF8pHmFpkAN28=";
            };
          }
          {
            name = "amneziawg naming, correctness fixes and selftests";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/compare/7727732d33bd4f4200b2893c2ead32eac5742d91...cfdedaaa0b0867366e8045771363a6b727caa9f3.diff";
              hash = "sha256-pO3wnes9IFp6QYF272289L+H7326psWFCHRNMS+uFeo=";
            };
          }
        ];
      });
    }
  );
}
