{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    any
    hasPrefix
    mkOption
    optional
    optionalString
    types
    ;

  resize = pkgs.writeShellScriptBin "resize" ''
    export PATH=${pkgs.coreutils}/bin

    if [ ! -t 0 ]; then
      exit 0
    fi

    TTY="$(tty)"
    if [[ "$TTY" != /dev/ttyS* ]] && [[ "$TTY" != /dev/ttyAMA* ]] && [[ "$TTY" != /dev/ttySIF* ]]; then
      exit 0
    fi

    old=$(stty -g)
    stty raw -echo min 0 time 5

    printf '\0337\033[r\033[999;999H\033[6n\0338' > /dev/tty
    IFS='[;R' read -r _ rows cols _ < /dev/tty

    stty "$old"
    stty cols "$cols" rows "$rows"
  '';
in

{
  options.modules.boot.consoles = mkOption {
    type = types.listOf types.str;
    default =
      optional pkgs.stdenv.hostPlatform.isAarch "ttyAMA0,115200"
      ++ optional pkgs.stdenv.hostPlatform.isRiscV64 "ttySIF0,115200"
      ++ [ "tty0" ];
    example = [ "ttyS2,115200" ];
    description = "Kernel console devices rendered as console= kernel parameters.";
  };

  config = {
    boot.kernelParams = map (console: "console=${console}") config.modules.boot.consoles;

    environment.loginShellInit = "${resize}/bin/resize";
    environment.systemPackages = [ resize ];

    systemd.services."serial-getty@".environment.TERM = "xterm-256color";

    boot.loader.grub.extraConfig =
      optionalString
        (any (
          console: hasPrefix "ttyS" console || hasPrefix "ttyAMA" console || hasPrefix "ttySIF" console
        ) config.modules.boot.consoles)
        ''
          serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
          terminal_input --append serial
          terminal_output --append serial
        '';

    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
      earlySetup = true;
    };
  };
}
