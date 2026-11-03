final: _prev:
let
  inherit (final.lib.kernel) yes;

  structuredExtraConfig = {
    BT_HCIUART_RTL = yes;
  };
in
{
  linuxPackages_allwinner = final.linuxKernel.packagesFor (
    final.linuxPackages.kernel.override (old: {
      structuredExtraConfig = (old.structuredExtraConfig or { }) // structuredExtraConfig;
    })
  );
}
