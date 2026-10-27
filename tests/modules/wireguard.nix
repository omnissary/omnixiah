{
  inputs,
  pkgs,
  self,
  system,
}:

let
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    concatStringsSep
    filter
    hasInfix
    nixosSystem
    optionals
    ;

  interface = {
    jc = 4;
    jmin = 70;
    jmax = 777;
    s1 = 20;
    s2 = 21;
    h1 = "1111-1200";
    i1 = "<b 0xd1><r 50>";
    contentPaddingAddition = "0-40";
    rekeyTimeout = "3-7";
    maxHandshakeAttempts = 5;
    randomTrailers = true;
    headerProtectionKeyFile = "/run/secrets/header-protection-key";
  };

  evaluate =
    extra:
    (nixosSystem {
      inherit system;
      specialArgs = {
        inherit self;
      };
      modules = [
        self.profiles.base
        {
          networking.hostName = "wireguard";
          networking.wireguard.enable = true;
          networking.wireguard.interfaces.wg0 = interface;
        }
        extra
      ];
    }).config;

  networkd = evaluate { networking.useNetworkd = true; };
  classic = evaluate { networking.useNetworkd = false; };

  networkdScript = networkd.systemd.services."wireguard-amnezia-wg0".script;
  classicScript = classic.systemd.services."wireguard-wg0".script;

  # A CPS descriptor contains shell metacharacters, so an unquoted value
  # turns the unit into a redirection.
  requiredFragments = [
    "i1 '<b 0xd1><r 50>'"
    "h1 1111-1200"
    "content-padding-addition 0-40"
    "rekey-timeout 3-7"
    "max-handshake-attempts 5"
    "random-trailers on"
    "disable-cookies off"
    "header-protection-key /run/secrets/header-protection-key"
  ];

  # Knobs left at zero or empty must not reach wg at all.
  forbiddenFragments = [
    "s3 0"
    "s4 0"
    "jmin 0"
    "rekey-after-time"
    "reject-after-time"
    "keepalive-timeout"
  ];

  missing = filter (fragment: !(hasInfix fragment networkdScript)) requiredFragments;

  present = filter (fragment: hasInfix fragment networkdScript) forbiddenFragments;

  errors =
    map (fragment: "networkd unit is missing ${fragment}") missing
    ++ map (fragment: "networkd unit should not carry ${fragment}") present
    ++ optionals (hasInfix "advanced-security" networkdScript) [
      "advanced-security is no longer a wg argument"
    ]
    ++ optionals (!hasInfix "i1 '<b 0xd1><r 50>'" classicScript) [
      "non-networkd unit does not quote CPS descriptors"
    ]
    ++ optionals (networkd.systemd.services ? "wireguard-wg0") [
      "networkd hosts should not get the interface unit variant"
    ];
in

if errors != [ ] then
  throw "wireguard module test failed:\n${concatStringsSep "\n" errors}"
else
  pkgs.writeText "omnixiah-module-wireguard" networkdScript
