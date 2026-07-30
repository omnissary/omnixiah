{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    listToAttrs
    literalExpression
    mapAttrsToList
    mkIf
    mkOption
    nameValuePair
    optionalString
    types
    ;

  cfg = config.networking.tc.shaper;

  mkShaperService =
    name: opts:
    nameValuePair "tc-shaper-${name}" {
      description = "Traffic shaper for interface ${name}";
      wantedBy = [ "multi-user.target" ];
      requires = [ "sys-subsystem-net-devices-${name}.device" ];
      bindsTo = [ "sys-subsystem-net-devices-${name}.device" ];
      after = [ "sys-subsystem-net-devices-${name}.device" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "tc-shaper-${name}-start" ''
          set -ex
          TC=${pkgs.iproute2}/bin/tc
          IP=${pkgs.iproute2}/bin/ip
          ETHTOOL=${pkgs.ethtool}/bin/ethtool

          ${optionalString opts.disableOffloading ''
            $ETHTOOL -K ${name} tso off gso off
          ''}

          $TC -s qdisc del dev ${name} root || true
          $TC -s qdisc del dev ${name} parent ffff: || true
          $TC -s qdisc del dev ${opts.ingress.ifb} root || true

          ${optionalString (opts.ingress.bandwidth != null) ''
            $IP link add ${opts.ingress.ifb} type ifb
            $IP link set dev ${opts.ingress.ifb} up
            $TC qdisc add dev ${name} handle ffff: ingress
            $TC filter add dev ${name} parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ${opts.ingress.ifb}
            $TC qdisc add dev ${opts.ingress.ifb} root handle 1: htb default 1
            $TC class add dev ${opts.ingress.ifb} parent 1: classid 1:1 htb rate ${opts.ingress.bandwidth} ceil ${opts.ingress.bandwidth} burst ${opts.ingress.burst}
            $TC qdisc add dev ${opts.ingress.ifb} parent 1:1 fq_codel limit 10240 target 5ms interval 100ms flows 1024
          ''}

          ${optionalString (opts.egress.bandwidth != null) ''
            $TC qdisc add dev ${name} root handle 1: htb default 1
            $TC class add dev ${name} parent 1: classid 1:1 htb rate ${opts.egress.bandwidth} ceil ${opts.egress.bandwidth} burst ${opts.egress.burst}
            $TC qdisc add dev ${name} parent 1:1 fq_codel limit 10240 target 5ms interval 100ms flows 1024
          ''}
        '';

        ExecStop = pkgs.writeShellScript "tc-shaper-${name}-stop" ''
          set -ex
          TC=${pkgs.iproute2}/bin/tc
          IP=${pkgs.iproute2}/bin/ip
          ETHTOOL=${pkgs.ethtool}/bin/ethtool

          $TC -s qdisc del dev ${name} root || true
          $TC -s qdisc del dev ${name} parent ffff: || true
          $TC -s qdisc del dev ${opts.ingress.ifb} root || true

          $IP link del ${opts.ingress.ifb} || true

          ${optionalString opts.disableOffloading ''
            $ETHTOOL -K ${name} tso on gso on
          ''}
        '';
      };
    };
in

{
  options.networking.tc.shaper = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable traffic shaping.";
    };
    interfaces = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable traffic shaping on this interface.";
            };
            disableOffloading = mkOption {
              type = types.bool;
              default = true;
              description = "Disable TSO/GSO before applying shaping.";
            };
            ingress = mkOption {
              description = "Ingress shaping configuration.";
              type = types.submodule {
                options = {
                  bandwidth = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    example = "5mbit";
                  };
                  burst = mkOption {
                    type = types.str;
                    default = "64kbit";
                  };
                  ifb = mkOption {
                    type = types.str;
                    default = "ifb0";
                  };
                };
              };
            };
            egress = mkOption {
              description = "Egress shaping configuration.";
              type = types.submodule {
                options = {
                  bandwidth = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    example = "1mbit";
                  };
                  burst = mkOption {
                    type = types.str;
                    default = "32kbit";
                  };
                };
              };
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          eth0 = {
            ingress.bandwidth = "2800kbit";
            egress.bandwidth = "700kbit";
          };
        }
      '';
      description = "Declarative traffic shaping for network interfaces.";
    };
  };

  config = mkIf (cfg.enable && cfg.interfaces != { }) {
    boot.kernelModules = [
      "ifb"
      "sch_htb"
      "sch_fq_codel"
      "act_mirred"
    ];
    systemd.services = listToAttrs (
      mapAttrsToList (
        name: opts:
        let
          finalOpts = opts // {
            ingress = opts.ingress // {
              ifb = "ifb_${name}";
            };
          };
        in
        mkShaperService name finalOpts
      ) (filterAttrs (_: value: value.enable) cfg.interfaces)
    );
  };
}
