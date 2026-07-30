{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) throw toJSON toString;
  inherit (lib)
    any
    attrValues
    cartesianProduct
    concatMapStringsSep
    concatStringsSep
    filter
    flatten
    length
    mkBefore
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalString
    toList
    types
    ;

  firewallTypes = types // {
    maybeListOf = type: types.either (types.listOf type) type;
  };

  cfg = config.networking.firewall;
in

{
  options.networking.firewall =
    let
      addressSubmodule = firewallTypes.submodule {
        options =
          let
            familyOption =
              family:
              mkOption {
                description = "IP address family";
                type = firewallTypes.maybeListOf (
                  firewallTypes.submodule {
                    options = {
                      family = mkOption {
                        description = "Address family";
                        type = firewallTypes.str;
                        default = family;
                      };
                      address = mkOption {
                        description = "IP address";
                        type = firewallTypes.str;
                      };
                      prefixLength = mkOption {
                        description = "IP CIDR";
                        type = firewallTypes.nullOr firewallTypes.ints.unsigned;
                        default = null;
                      };
                    };
                  }
                );
                apply = toList;
                default = [ ];
              };
          in
          {
            ipv4 = familyOption "ipv4";
            ipv6 = familyOption "ipv6";
          };
      };

      mkRuleSubmodule =
        chain:
        firewallTypes.submodule {
          options =
            let
              addresses = mkOption {
                description = "List of network addresses to match";
                type = addressSubmodule;
                default = { };
                example = {
                  ipv4 = [
                    { address = "192.168.0.1"; }
                    {
                      address = "10.0.0.0";
                      prefixLength = 8;
                    }
                  ];
                  ipv6 = [
                    {
                      address = "fefe::";
                      prefixLength = 64;
                    }
                  ];
                };
              };
            in
            {
              ports = mkOption {
                description = "List of ports to match";
                type = firewallTypes.maybeListOf firewallTypes.port;
                apply = toList;
                default = [ ];
                example = [ 22 ];
              };
              portRanges = mkOption {
                description = "List of port ranges to match";
                type = firewallTypes.maybeListOf (
                  firewallTypes.submodule {
                    options = {
                      from = mkOption {
                        type = firewallTypes.port;
                      };
                      to = mkOption {
                        type = firewallTypes.port;
                      };
                    };
                  }
                );
                apply = toList;
                default = [ ];
                example = [
                  {
                    from = 33000;
                    to = 34000;
                  }
                ];
              };
              protocols = mkOption {
                description = "List of protocols to match";
                type = firewallTypes.maybeListOf firewallTypes.str;
                apply = toList;
                default = [ ];
                example = [ "tcp" ];
              };
              interfaces = mkOption {
                description = "List of network interfaces to match";
                type = firewallTypes.maybeListOf firewallTypes.str;
                apply = toList;
                default = [ ];
                example = [ "enp3s0" ];
              };
              sources = addresses;
              chain = mkOption {
                description = "Chain name to jump into if rule matches";
                readOnly = true;
                default = chain;
              };
            };
        };

      portscanSubmodule = firewallTypes.submodule {
        options = {
          enable = mkEnableOption "portscan firewall mitigation";
          excludeInterfaces = mkOption {
            description = "List of network interfaces to exclude from portscan mitigation";
            type = firewallTypes.listOf firewallTypes.str;
            default = [ ];
            example = [
              "lo"
              "veth+"
            ];
          };
          window = mkOption {
            description = "Amount of seconds to hold counters for an IP and port pair";
            type = firewallTypes.int;
            default = 1800;
          };
          packets = mkOption {
            description = "Minimal packet count on distinct ports within the window before mitigation";
            type = firewallTypes.int;
            default = 10;
          };
          bantime = mkOption {
            description = "Duration to ban an offender after mitigation activation";
            type = firewallTypes.str;
            default = "48h";
          };
        };
      };

      inactivednsSubmodule = firewallTypes.submodule {
        options = {
          enable = mkEnableOption "inactive DNS firewall mitigation";
          window = mkOption {
            description = "Hold counters for this number of seconds";
            type = firewallTypes.int;
            default = 1800;
          };
          max = mkOption {
            description = "Terminated inactive connections within the window before mitigation";
            type = firewallTypes.int;
            default = 30;
          };
          bantime = mkOption {
            description = "Duration to ban an offender after mitigation activation";
            type = firewallTypes.str;
            default = "48h";
          };
        };
      };

      dnsamplificationSubmodule = firewallTypes.submodule {
        options = {
          enable = mkEnableOption "DNS amplification firewall mitigation";
          window = mkOption {
            description = "Hold counters for this number of seconds";
            type = firewallTypes.int;
            default = 3600;
          };
          max = mkOption {
            description = "Matched log records within the window before mitigation";
            type = firewallTypes.int;
            default = 15;
          };
          bantime = mkOption {
            description = "Duration to ban an offender after mitigation activation";
            type = firewallTypes.str;
            default = "48h";
          };
        };
      };
    in
    {
      accept = mkOption {
        description = "Rules that accept matching firewall traffic";
        type = firewallTypes.listOf (mkRuleSubmodule "nixos-fw-accept");
        default = [ ];
      };
      rejectSilently = mkOption {
        description = "Rules that reject matching firewall traffic without logging";
        type = firewallTypes.listOf (mkRuleSubmodule "nixos-fw-refuse");
        default = [ ];
      };
      reject = mkOption {
        description = "Rules that reject matching firewall traffic with logging";
        type = firewallTypes.listOf (mkRuleSubmodule "nixos-fw-log-refuse");
        default = [ ];
      };
      drop = mkOption {
        description = "Rules that drop matching firewall traffic without logging";
        type = firewallTypes.listOf (mkRuleSubmodule "DROP");
        default = [ ];
      };

      mitigations = {
        portscan = mkOption {
          type = portscanSubmodule;
          default = { };
        };
        inactivedns = mkOption {
          type = inactivednsSubmodule;
          default = { };
        };
        dnsamplification = mkOption {
          type = dnsamplificationSubmodule;
          default = { };
        };
      };
    };

  config =
    let
      nonNull = value: optionalString (value != null);

      listOrNull = list: if length list == 0 then [ null ] else list;

      mkRules =
        {
          ports,
          portRanges,
          protocols,
          interfaces,
          sources,
          chain,
          ...
        }:
        let
          portsWithRanges =
            map toString ports ++ map (range: "${toString range.from}:${toString range.to}") portRanges;
        in
        concatMapStringsSep "\n"
          (
            {
              port,
              protocol,
              interface,
              source,
              chain,
            }:
            let
              command =
                if source == null then
                  "ip46tables"
                else
                  {
                    ipv4 = "iptables";
                    ipv6 = "ip6tables";
                  }
                  .${source.family};

              portParam = nonNull port "--dport ${port}";
              protocolParam = nonNull protocol "-p ${protocol}";
              interfaceParam = nonNull interface "-i ${interface}";
              sourceParam =
                let
                  cidr = nonNull source.prefixLength "/${toString source.prefixLength}";
                in
                nonNull source "-s ${source.address}${cidr}";
            in
            concatStringsSep " " (
              filter (param: param != "") [
                command
                "-A nixos-fw"
                interfaceParam
                protocolParam
                portParam
                sourceParam
                "-j ${chain}"
              ]
            )
          )
          (cartesianProduct {
            port = listOrNull portsWithRanges;
            protocol = listOrNull protocols;
            interface = listOrNull interfaces;
            source = listOrNull (flatten (attrValues sources));
            chain = [ chain ];
          });

      ruleSets = [
        cfg.accept
        cfg.rejectSilently
        cfg.reject
        cfg.drop
      ];

      hasRulesMissingProtocols = any (any (
        rule: (length rule.ports > 0 || length rule.portRanges > 0) && length rule.protocols == 0
      )) ruleSets;
    in
    mkMerge [
      {
        networking.firewall.extraCommands =
          assert
            !hasRulesMissingProtocols
            || throw "Some firewall rules have ports or portRanges but no protocols: ${toJSON ruleSets}";
          mkBefore (concatMapStringsSep "\n" (concatMapStringsSep "\n" mkRules) ruleSets);
      }

      (mkIf cfg.mitigations.portscan.enable (
        let
          mitigation = cfg.mitigations.portscan;
          portscanChain = "nixos-fw-portscan";
          portscanExcludeCommands = concatMapStringsSep "\n" (
            iface: "iptables -A ${portscanChain} -i ${iface} -j RETURN"
          ) mitigation.excludeInterfaces;
          portscanExcludeCommands6 = concatMapStringsSep "\n" (
            iface: "ip6tables -A ${portscanChain} -i ${iface} -j RETURN"
          ) mitigation.excludeInterfaces;
        in
        {
          networking.firewall = {
            extraPackages = [ pkgs.ipset ];
            extraCommands = ''
              ipset create portscan4_track hash:ip,port timeout ${toString mitigation.window} counters || true
              ipset create portscan4_count hash:ip timeout ${toString mitigation.window} counters || true
              ipset create portscan6_track hash:ip,port family inet6 timeout ${toString mitigation.window} counters || true
              ipset create portscan6_count hash:ip family inet6 timeout ${toString mitigation.window} counters || true

              iptables -N ${portscanChain} || true
              iptables -I nixos-fw-log-refuse -j ${portscanChain}

              ${portscanExcludeCommands}
              iptables -A ${portscanChain} -m set ! --match-set portscan4_track src,dst ! --update-counters \
                       -m set --match-set portscan4_count src --update-counters \
                       -j SET --add-set portscan4_count src
              iptables -A ${portscanChain} -m set ! --match-set portscan4_track src,dst -j SET --add-set portscan4_count src
              iptables -A ${portscanChain} -j SET --add-set portscan4_track src,dst
              iptables -A ${portscanChain} -m set --match-set portscan4_count src ! --update-counters \
                       --packets-gt ${toString mitigation.packets} -m hashlimit \
                       --hashlimit-name portscan_log --hashlimit-mode srcip --hashlimit 1/sec --hashlimit-burst 1 \
                       -j LOG --log-prefix "portscan: " --log-level 6

              ip6tables -N ${portscanChain} || true
              ip6tables -I nixos-fw-log-refuse -j ${portscanChain}

              ${portscanExcludeCommands6}
              ip6tables -A ${portscanChain} -m set ! --match-set portscan6_track src,dst ! --update-counters \
                        -m set --match-set portscan6_count src --update-counters \
                        -j SET --add-set portscan6_count src
              ip6tables -A ${portscanChain} -m set ! --match-set portscan6_track src,dst -j SET --add-set portscan6_count src
              ip6tables -A ${portscanChain} -j SET --add-set portscan6_track src,dst
              ip6tables -A ${portscanChain} -m set --match-set portscan6_count src ! --update-counters \
                        --packets-gt ${toString mitigation.packets} -m hashlimit \
                        --hashlimit-name portscan_log6 --hashlimit-mode srcip --hashlimit 1/sec --hashlimit-burst 1 \
                        -j LOG --log-prefix "portscan: " --log-level 6
            '';
            extraStopCommands = ''
              iptables -D nixos-fw-log-refuse -j ${portscanChain} || true
              iptables -F ${portscanChain} || true
              iptables -X ${portscanChain} || true

              ip6tables -D nixos-fw-log-refuse -j ${portscanChain} || true
              ip6tables -F ${portscanChain} || true
              ip6tables -X ${portscanChain} || true

              ipset destroy portscan4_track || true
              ipset destroy portscan4_count || true
              ipset destroy portscan6_track || true
              ipset destroy portscan6_count || true
            '';
          };

          environment.etc = mkIf config.services.fail2ban.enable {
            "fail2ban/filter.d/ipset-portscan.local".text = ''
              [Definition]
              failregex = ^.*portscan: IN=\S+ OUT=\S* MAC=\S+ SRC=<HOST> DST=\S+.*$
              ignoreregex =
            '';
          };

          services.fail2ban.jails.portscan.settings = {
            enabled = true;
            journalmatch = "_TRANSPORT=kernel";
            filter = "ipset-portscan";
            banaction = "%(banaction_allports)s";
            protocol = "all";
            findtime = toString mitigation.window;
            maxretry = 1;
            inherit (mitigation) bantime;
          };
        }
      ))

      (mkIf cfg.mitigations.inactivedns.enable (
        let
          mitigation = cfg.mitigations.inactivedns;
        in
        {
          environment.etc = mkIf config.services.fail2ban.enable {
            "fail2ban/filter.d/inactivedns.local".text = ''
              [Definition]
              failregex = ^.*notice: TCP, terminated inactive client, address <HOST>@.*$
              ignoreregex =
            '';
          };

          services.fail2ban.jails.inactivedns.settings = {
            enabled = true;
            journalmatch = "_SYSTEMD_UNIT=knot.service";
            filter = "inactivedns";
            banaction = "%(banaction_allports)s";
            protocol = "all";
            findtime = toString mitigation.window;
            maxretry = mitigation.max;
            inherit (mitigation) bantime;
          };
        }
      ))

      (mkIf cfg.mitigations.dnsamplification.enable (
        let
          mitigation = cfg.mitigations.dnsamplification;
        in
        {
          environment.etc = mkIf config.services.fail2ban.enable {
            "fail2ban/filter.d/dnsamplification.local".text = ''
              [Definition]
              failregex = ^.*notice: module 'mod-rrl/default', address <HOST> TCP limited.*$
              ignoreregex =
            '';
          };

          services.fail2ban.jails.dnsamplification.settings = {
            enabled = true;
            journalmatch = "_SYSTEMD_UNIT=knot.service";
            filter = "dnsamplification";
            banaction = "%(banaction_allports)s";
            protocol = "all";
            findtime = toString mitigation.window;
            maxretry = mitigation.max;
            inherit (mitigation) bantime;
          };
        }
      ))
    ];
}
