{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    isInt
    isString
    ;

  inherit (lib)
    types
    mkOption
    mkMerge
    mkIf
    mkAfter
    optionalString
    attrNames
    listToAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
    concatStringsSep
    escapeShellArg
    ;

  cfg = config.networking.wireguard;

  rangeType = types.oneOf [
    types.int
    types.str
  ];

  # Option name to wg(8) argument. Empty values are left out, so an
  # unconfigured knob keeps the kernel default.
  valueFlags = {
    jc = "jc";
    jmin = "jmin";
    jmax = "jmax";
    s1 = "s1";
    s2 = "s2";
    s3 = "s3";
    s4 = "s4";
    h1 = "h1";
    h2 = "h2";
    h3 = "h3";
    h4 = "h4";
    i1 = "i1";
    i2 = "i2";
    i3 = "i3";
    i4 = "i4";
    i5 = "i5";
    contentPaddingAddition = "content-padding-addition";
    rekeyAfterTime = "rekey-after-time";
    rekeyTimeout = "rekey-timeout";
    rejectAfterTime = "reject-after-time";
    keepaliveTimeout = "keepalive-timeout";
    maxHandshakeAttempts = "max-handshake-attempts";
  };

  # Always emitted, so flipping one back to false reaches the device.
  boolFlags = {
    randomTrailers = "random-trailers";
    disableCookies = "disable-cookies";
  };

  # A zero or empty knob is left out, so the kernel keeps its own default.
  renderValue =
    flag: value:
    if isInt value && value > 0 then
      " ${flag} ${toString value}"
    else if isString value && value != "" then
      " ${flag} ${escapeShellArg value}"
    else
      "";

  interfaceArguments =
    interface:
    concatStringsSep "" (
      mapAttrsToList (option: flag: renderValue flag interface.${option}) valueFlags
      ++ mapAttrsToList (
        option: flag: " ${flag} ${if interface.${option} then "on" else "off"}"
      ) boolFlags
      ++ [
        (optionalString (
          interface.headerProtectionKeyFile != null
        ) " header-protection-key ${escapeShellArg interface.headerProtectionKeyFile}")
      ]
    );

  valueOption =
    description: default:
    mkOption {
      inherit description default;
      type = rangeType;
    };

  rangeDescription = "a value or an inclusive low-high range";
in
{
  options.networking.wireguard = {
    interfaces = mkOption {
      type = types.attrsOf (
        types.submodule (_: {
          options = {
            jc = valueOption "Junk packet count (can be anywhere between 1-128)" 0;
            jmin = valueOption "Junk packet minimum size" 0;
            jmax = valueOption "Junk packet maximum size, at most 32768" 0;

            s1 = valueOption "Init packet junk size" 0;
            s2 = valueOption "Response packet junk size" 0;
            s3 = valueOption "Cookie packet junk size" 0;
            s4 = valueOption "Transport packet junk size" 0;

            h1 = valueOption "Init packet magic header, ${rangeDescription}" 1;
            h2 = valueOption "Response packet magic header, ${rangeDescription}" 2;
            h3 = valueOption "Cookie packet magic header, ${rangeDescription}" 3;
            h4 = valueOption "Transport packet magic header, ${rangeDescription}" 4;

            i1 = valueOption "CPS packet descriptor 1" "";
            i2 = valueOption "CPS packet descriptor 2" "";
            i3 = valueOption "CPS packet descriptor 3" "";
            i4 = valueOption "CPS packet descriptor 4" "";
            i5 = valueOption "CPS packet descriptor 5" "";

            contentPaddingAddition = valueOption "Extra padding inside the encrypted content of transport packets, ${rangeDescription}" "";
            rekeyAfterTime = valueOption "Overrides REKEY_AFTER_TIME, seconds, ${rangeDescription}" "";
            rekeyTimeout = valueOption "Overrides REKEY_TIMEOUT, seconds, ${rangeDescription}" "";
            rejectAfterTime = valueOption "Overrides REJECT_AFTER_TIME, seconds, ${rangeDescription}" "";
            keepaliveTimeout = valueOption "Overrides KEEPALIVE_TIMEOUT, seconds, ${rangeDescription}" "";
            maxHandshakeAttempts = valueOption "Overrides MAX_TIMER_HANDSHAKES, ${rangeDescription}" "";

            headerProtectionKeyFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/private/header_protection_key";
              description = ''
                Path to a file holding the base64 header protection key. A
                string rather than a path, so the key is read at runtime
                instead of being copied into the world readable store. Every
                s1-s4 must be at least 12 so each padding can carry the
                per-packet nonce, and the same key must be set on every peer.
              '';
            };

            randomTrailers = mkOption {
              type = types.bool;
              default = false;
              description = "Append a random number of bytes to each packet";
            };
            disableCookies = mkOption {
              type = types.bool;
              default = false;
              description = "Never enter the under load state, so no cookie reply is ever sent";
            };
          };
        })
      );
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.wireguard-tools
      ];

      systemd.services =
        let
          interfaces = attrNames cfg.interfaces;
        in
        listToAttrs (
          map (
            name:
            nameValuePair "network-addresses-${name}" {
              requires = [ "wireguard-${name}.service" ];
            }
          ) interfaces
        );
    }
    {
      systemd.services =
        let
          interfaceUnits = mapAttrs' (
            name: interface:
            nameValuePair "wireguard-${name}" {
              script = mkAfter ''
                wg set "${name}"${interfaceArguments interface}
              '';
            }
          ) cfg.interfaces;

          networkdUnits = mapAttrs' (
            name: interface:
            nameValuePair "wireguard-obfuscation-${name}" {
              description = "Apply obfuscation parameters to WireGuard interface ${name}";
              after = [ "sys-subsystem-net-devices-${name}.device" ];
              bindsTo = [ "sys-subsystem-net-devices-${name}.device" ];
              wantedBy = [ "sys-subsystem-net-devices-${name}.device" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [ pkgs.wireguard-tools ];
              script = ''
                wg set "${name}"${interfaceArguments interface}
              '';
            }
          ) cfg.interfaces;
        in
        if config.networking.useNetworkd then networkdUnits else interfaceUnits;
    }
  ]);
}
