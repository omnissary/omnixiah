{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkForce mkIf toHexString;
  inherit (pkgs) buildPackages;
  inherit (buildPackages)
    android-tools
    closureInfo
    mtdutils
    sunxi-tools
    ubootTools
    writeShellScript
    writeText
    ;

  inherit (config.hardware.allwinner) uBoot;
  inherit (config.boot.loader.generic-extlinux-compatible) populateCmd;
  toplevel = config.system.build.toplevel;
  closure = closureInfo { rootPaths = [ toplevel ]; };

  page = 16384;
  eraseBlock = 4194304;
  slcEraseBlock = eraseBlock / 2;
  logicalEraseBlock = slcEraseBlock - 2 * page;
  maxLogicalEraseBlocks = 4096;
  pagesPerEraseBlock = eraseBlock / page;

  oob = {
    hynix = 1664;
    toshiba = 1280;
  };

  address = {
    script = "0x44100000";
    splHynix = "0x46000000";
    splToshiba = "0x47000000";
    uBoot = "0x48000000";
  };

  fastbootVendor = "0x1f3a";

  # The rootfs partition in nand.dts is sized for the 8 GB Hynix part. On the
  # 4 GB Toshiba part the kernel truncates it with a warning, and the
  # autoresize volume below grows to whatever UBI attaches.
  ubinizeConfig = writeText "ubinize.cfg" ''
    [rootfs]
    mode=ubi
    vol_id=0
    vol_type=dynamic
    vol_name=rootfs
    vol_alignment=1
    vol_flags=autoresize
    image=rootfs.ubifs
  '';

  flashCommands = writeText "nand-flash.cmd" ''
    echo == erasing NAND ==
    nand erase.chip
    setenv spl_img ${address.splHynix}
    if itest.b *0x1c03035 == 40; then echo "Toshiba NAND detected"; setenv spl_img ${address.splToshiba}; fi
    if itest.b *0x1c03035 == 60; then echo "Hynix NAND detected"; setenv spl_img ${address.splHynix}; fi
    nand write.raw.noverify ''${spl_img} 0x0 0x${toHexString pagesPerEraseBlock}
    nand write.raw.noverify ''${spl_img} 0x400000 0x${toHexString pagesPerEraseBlock}
    nand write ${address.uBoot} 0x800000 0x400000
    nand write ${address.uBoot} 0xc00000 0x400000
    setenv mtdparts 'mtdparts=nand0:4m(SPL),4m(SPL.backup),4m(U-Boot),4m(U-Boot.backup),-(rootfs_a)slc'
    echo == entering fastboot ==
    fastboot usb 0
  '';

  # Not bit-reproducible: sunxi-nand-image-builder fills the unused part of
  # every page from /dev/urandom, which is intended for MLC NAND.
  nandImage =
    pkgs.runCommand "chip-nand-image"
      {
        nativeBuildInputs = [
          android-tools
          mtdutils
          sunxi-tools
          ubootTools
        ];
      }
      ''
        splImage() {
          local oob=$1 out=$2
          sunxi-nand-image-builder -c 64/1024 -p ${toString page} -o "$oob" -u 1024 -e ${toString eraseBlock} -b \
            -s ${uBoot}/sunxi-spl.bin spl-one.nand
          local onePages=$(( $(stat -c%s spl-one.nand) / (${toString page} + oob) ))
          local padBytes=$(( (64 - onePages) * 1024 ))
          : > "$out"
          for _ in $(seq ${toString (pagesPerEraseBlock / 64)}); do
            head -c "$padBytes" /dev/urandom > pad.bin
            sunxi-nand-image-builder -c 64/1024 -p ${toString page} -o "$oob" -u 1024 -e ${toString eraseBlock} -b \
              -s pad.bin pad.nand
            cat spl-one.nand pad.nand >> "$out"
          done
        }

        mkdir -p $out
        splImage ${toString oob.hynix} $out/spl-hynix.nand
        splImage ${toString oob.toshiba} $out/spl-toshiba.nand
        dd if=${uBoot}/u-boot-dtb.bin of=$out/u-boot.nand bs=${toString eraseBlock} conv=sync status=none
        cp ${uBoot}/u-boot-sunxi-with-spl.bin $out/
        mkimage -A arm -O linux -T script -C none -n chip-nand -d ${flashCommands} $out/flash.scr

        mkdir -p root/nix/store root/boot
        xargs -I % cp -a --reflink=auto % -t root/nix/store/ < ${closure}/store-paths
        cp ${closure}/registration root/nix-path-registration
        ${populateCmd} -c ${toplevel} -d root/boot

        mkfs.ubifs -r root -m ${toString page} -e ${toString logicalEraseBlock} -c ${toString maxLogicalEraseBlocks} \
          -x lzo -U -o rootfs.ubifs
        ubinize -o rootfs.ubi -p ${toString slcEraseBlock} -m ${toString page} -s ${toString page} ${ubinizeConfig}
        img2simg rootfs.ubi $out/rootfs.ubi.sparse ${toString slcEraseBlock}
      '';

  nandFlash = writeShellScript "chip-nand-flash" ''
    set -euo pipefail
    image=${nandImage}
    fastboot=(${android-tools}/bin/fastboot -i ${fastbootVendor})

    echo "connect the CHIP micro-USB port with FEL jumpered to GND"
    until ${sunxi-tools}/bin/sunxi-fel ver >/dev/null 2>&1; do sleep 0.5; done

    ${sunxi-tools}/bin/sunxi-fel -v -p uboot "$image/u-boot-sunxi-with-spl.bin" \
      write ${address.script} "$image/flash.scr" \
      write ${address.splHynix} "$image/spl-hynix.nand" \
      write ${address.splToshiba} "$image/spl-toshiba.nand" \
      write ${address.uBoot} "$image/u-boot.nand"

    echo "waiting for fastboot"
    until [ -n "$("''${fastboot[@]}" devices 2>/dev/null)" ]; do sleep 0.5; done
    "''${fastboot[@]}" flash rootfs "$image/rootfs.ubi.sparse"
    "''${fastboot[@]}" reboot
    echo "done, remove the FEL jumper"
  '';
in

{
  config = mkIf (config.hardware.allwinner.chip.storage == "nand") {
    hardware.deviceTree.overlays = [
      {
        name = "chip-nand";
        dtsFile = ./nand.dts;
      }
    ];

    boot.kernelParams = [ "ubi.mtd=rootfs" ];

    fileSystems."/" = mkForce {
      device = "ubi0:rootfs";
      fsType = "ubifs";
      options = [ "noatime" ];
    };

    sdImage.expandOnBoot = false;

    environment.systemPackages = [ pkgs.mtdutils ];

    systemd.services.ubihealthd = {
      description = "UBI NAND health watchdog";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.mtdutils}/bin/ubihealthd -d /dev/ubi0 -f /var/cache/ubihealthd/stats";
        CacheDirectory = "ubihealthd";
        Restart = "on-failure";
      };
    };

    system.build = {
      inherit nandImage nandFlash;
    };
  };
}
