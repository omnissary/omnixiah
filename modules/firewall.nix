{
  config,
  lib,
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
    {
      networking.firewall.extraCommands =
        assert
          !hasRulesMissingProtocols
          || throw "Some firewall rules have ports or portRanges but no protocols: ${toJSON ruleSets}";
        mkBefore (concatMapStringsSep "\n" (concatMapStringsSep "\n" mkRules) ruleSets);
    };
}
