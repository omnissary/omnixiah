final: _prev: {
  linux-chip = final.callPackage (
    { pkgs, lib, ... }:

    let
      inherit (lib.kernel) unset yes;
      inherit (pkgs.linuxKernel) kernels packagesFor;

      chipKernelConfig = {
        ARCH_SUNXI = yes; # Enable Allwinner SoC support
        PINCTRL_SUNXI = yes; # Pin control for Allwinner
        MTD_NAND_SUNXI = yes; # NAND support (may not work fully in mainline)
        SUNXI_RSB = yes; # Reduced Serial Bus for Allwinner
        SUNXI_SRAM = yes; # SRAM controller
        RTC_DRV_SUNXI = yes; # Real-Time clock
        PWM_SUN4I = yes; # PWM for Allwinner
        SUNXI_WATCHDOG = yes; # Watchdog timer
        KEYBOARD_SUN4I_LRADC = yes; # Keyboard
        USB_DWC2_SUNXI = yes; # USB controller
        PHY_SUN4I_USB = yes; # USB PHY
        CLK_SUNXI = yes; # Clock Control Unit
        DRM_SUN4I = yes; # Display Rendering Manager for Allwinner
        CAN_TI_HECC = unset; # Failing to build
        DRM_NOUVEAU = unset;
        DRM_AMDGPU = unset;
      };
    in
    {
      linux_6_12_chip = packagesFor (
        kernels.linux_6_12.override {
          structuredExtraConfig = chipKernelConfig;
        }
      );
    }
  ) { };
}
