_self: super: {
  wiringop = super.wiringpi.overrideAttrs (
    oldAttrs:
    let
      srcAll = super.fetchFromGitHub {
        owner = "orangepi-xunlong";
        repo = "wiringOP";
        rev = "a81284783cdfab89a68a630b4abce9e14424f931";
        hash = "sha256-9fOqP2MaofzpE7b5+RdtCAdJJfHZrA7mexFDPIBA9Lg=";
      };
      inherit (oldAttrs.passthru) mkSubProject;
      wiringPi = mkSubProject {
        subprj = "wiringPi";
        src = srcAll;
        buildInputs = [ super.libxcrypt ];
      };
      devLib = mkSubProject {
        subprj = "devLib";
        src = srcAll;
        buildInputs = [ wiringPi ];
      };
      wiringPiD = mkSubProject {
        subprj = "wiringPiD";
        src = srcAll;
        buildInputs = [
          super.libxcrypt
          wiringPi
          devLib
        ];
      };
      gpio =
        (mkSubProject {
          subprj = "gpio";
          src = srcAll;
          buildInputs = [
            super.libxcrypt
            wiringPi
            devLib
          ];
        }).overrideAttrs
          (_: {
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin"
              cp -v gpio "$out/bin/"
              runHook postInstall
            '';
          });
    in
    {
      passthru = oldAttrs.passthru // {
        src = srcAll;
        inherit
          wiringPi
          devLib
          wiringPiD
          gpio
          ;
      };
      paths = [
        wiringPi
        devLib
        wiringPiD
        gpio
      ];
      meta = oldAttrs.meta // {
        homepage = "https://github.com/orangepi-xunlong/wiringOP";
      };
    }
  );
}
