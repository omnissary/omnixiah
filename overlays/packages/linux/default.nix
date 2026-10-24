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
            name = "pack magic header ranges into a single integer";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/bebdc16cc82d63629986b534ee85afe5d9389b3c.patch";
              hash = "sha256-HLhMF5SZEvbitiU8iv6ost5KvPALoi1iwFBqJJFH+K0=";
            };
          }
          {
            name = "reserve an attribute range for local extensions";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/4192daa20d2d000904944eef64c1098aab6d96e1.patch";
              hash = "sha256-aoWQLq0z3K69n+ic3oBJMfYiIiPxhX2RIP8rCHaOdxw=";
            };
          }
          {
            name = "drop advanced security gating";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/a281e2c6f4dad46d21318d055592bfe11902b874.patch";
              hash = "sha256-y00Hihamjk4uYjabcCKuVkhPc+46fBtvduy3BCckDFA=";
            };
          }
          {
            name = "resolve packet type and padding once per skb";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/d852d8fbb9f4eec1384187681d24ae9966b28d2c.patch";
              hash = "sha256-X7sZt34SpGuJaJCvtIx1LP8vkAzPBk0V9V7D6Yy22tE=";
            };
          }
          {
            name = "add header protection";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/35cd73a1d91d38edf981a15ed33051f8257be5ec.patch";
              hash = "sha256-5DHVq9TSBs0cCPc9U2jKSsIzBP/h0lfqhSc8Ta5S3tw=";
            };
          }
          {
            name = "add content padding addition";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/acbe05a38725dbc236d13e47027f8eac37ecbed8.patch";
              hash = "sha256-CzAjKR+7/x6FV+19ZvfgBa/znPvelLrezplMuoRb81U=";
            };
          }
          {
            name = "make handshake timings configurable";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/e69ce636075ee1ec76e9d87e4e484d62508a5b4c.patch";
              hash = "sha256-+xyTAhNzwJP6hzG531/9SZfPlrP2NsmjxNoGGAtSeLE=";
            };
          }
          {
            name = "use reject_after_time for the zero key material timer";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/cc18ba88b4755a965bcdd7ee736cd67800a384ab.patch";
              hash = "sha256-pieMHfjtYndLmt6jJo4uSn0Utkhry9tjsE8t5xNdAMk=";
            };
          }
          {
            name = "use a u16 range for persistent keepalive";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/b45adad3710bcfc20a1a0cde679214eb59e3b05d.patch";
              hash = "sha256-whbbjF8nUCZrFdSBunydptFQ7Za9G3iD46nt1UDAI0s=";
            };
          }
          {
            name = "add random trailers";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/4305ab4d288ad09287cca0febfba81a662a0ca90.patch";
              hash = "sha256-4wiI/Do/Bg2FVwPEEW5BVDDrkWdbUaDeqKQV76WkoVc=";
            };
          }
          {
            name = "add cookie disabling";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/5e1b76042db202327ae238f782c6faab82c02955.patch";
              hash = "sha256-foJYzwqLQPDlcBT2a3W04Jne5GFtNnsLThNXgY9uG7U=";
            };
          }
          {
            name = "indent wg_peer_skb_padding_addition with tabs";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/81dfd86c8fb2f628609abff8cc3e856e9ce1719d.patch";
              hash = "sha256-IsBlXAvx09i0hvhYDXFRYYI4iRhab0Fn5h+IbjWodEI=";
            };
          }
          {
            name = "cap JunkPacketMaxSize at 32768";
            patch = super.fetchurl {
              url = "https://git.tatikoma.dev/omnixiah/linux/commit/7727732d33bd4f4200b2893c2ead32eac5742d91.patch";
              hash = "sha256-vRwyzDsBkR/Q54vrHv01KXcXGHIyEoFUNykYN1Ud6xM=";
            };
          }
        ];
      });
    }
  );
}
