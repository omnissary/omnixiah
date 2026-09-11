final: _prev: {
  xrofi = final.callPackage (
    {
      rofi,
      rofi-calc,
      rofi-pass,
      symlinkJoin,
    }:

    let
      rofiWithPlugins = rofi.override {
        plugins = [ rofi-calc ];
      };
      rofiPass = rofi-pass.override { rofi = rofiWithPlugins; };
    in

    symlinkJoin {
      name = "xrofi";
      paths = [
        rofiPass
        rofiWithPlugins
      ];
    }
  ) { };
}
