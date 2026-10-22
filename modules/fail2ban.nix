{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) toString;
  inherit (lib)
    concatMapStringsSep
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.services.fail2ban.mitigations;
  inherit (cfg) portScan;
  portScanChain = "nixos-fw-portscan";

  ignoreInterfaceCommands =
    command:
    concatMapStringsSep "\n" (
      interface: "${command} -A ${portScanChain} -i ${interface} -j RETURN"
    ) portScan.ignoreInterfaces;
in

{
  options.services.fail2ban.mitigations = {
    portScan = {
      enable = mkEnableOption "port scan detection and banning";
      ignoreInterfaces = mkOption {
        description = "Network interfaces excluded from port scan detection";
        type = types.listOf types.str;
        default = [ ];
        example = [
          "lo"
          "veth+"
        ];
      };
      findtime = mkOption {
        description = "Seconds during which distinct destination ports are counted";
        type = types.ints.positive;
        default = 1800;
      };
      maxPorts = mkOption {
        description = "Distinct destination ports allowed within findtime before banning the source";
        type = types.ints.positive;
        default = 10;
      };
    };

    knotInactiveClients.enable = mkEnableOption "banning clients that leave inactive Knot DNS connections";
  };

  config = mkMerge [
    (mkIf portScan.enable {
      assertions = [
        {
          assertion = config.networking.firewall.enable;
          message = "services.fail2ban.mitigations.portScan requires networking.firewall.enable";
        }
        {
          assertion = config.networking.firewall.backend == "iptables";
          message = "services.fail2ban.mitigations.portScan supports only the iptables firewall backend";
        }
      ];

      networking.firewall = {
        extraPackages = [ pkgs.ipset ];
        extraCommands = ''
          ipset create portscan4_track hash:ip,port timeout ${toString portScan.findtime} counters || true
          ipset create portscan4_count hash:ip timeout ${toString portScan.findtime} counters || true
          ipset create portscan6_track hash:ip,port family inet6 timeout ${toString portScan.findtime} counters || true
          ipset create portscan6_count hash:ip family inet6 timeout ${toString portScan.findtime} counters || true

          iptables -N ${portScanChain} || true
          iptables -I nixos-fw-log-refuse -j ${portScanChain}

          ${ignoreInterfaceCommands "iptables"}
          iptables -A ${portScanChain} -m set ! --match-set portscan4_track src,dst ! --update-counters \
                   -m set --match-set portscan4_count src --update-counters \
                   -j SET --add-set portscan4_count src
          iptables -A ${portScanChain} -m set ! --match-set portscan4_track src,dst -j SET --add-set portscan4_count src
          iptables -A ${portScanChain} -j SET --add-set portscan4_track src,dst
          iptables -A ${portScanChain} -m set --match-set portscan4_count src ! --update-counters \
                   --packets-gt ${toString portScan.maxPorts} -m hashlimit \
                   --hashlimit-name portscan_log --hashlimit-mode srcip --hashlimit 1/sec --hashlimit-burst 1 \
                   -j LOG --log-prefix "portscan: " --log-level 6

          ip6tables -N ${portScanChain} || true
          ip6tables -I nixos-fw-log-refuse -j ${portScanChain}

          ${ignoreInterfaceCommands "ip6tables"}
          ip6tables -A ${portScanChain} -m set ! --match-set portscan6_track src,dst ! --update-counters \
                    -m set --match-set portscan6_count src --update-counters \
                    -j SET --add-set portscan6_count src
          ip6tables -A ${portScanChain} -m set ! --match-set portscan6_track src,dst -j SET --add-set portscan6_count src
          ip6tables -A ${portScanChain} -j SET --add-set portscan6_track src,dst
          ip6tables -A ${portScanChain} -m set --match-set portscan6_count src ! --update-counters \
                    --packets-gt ${toString portScan.maxPorts} -m hashlimit \
                    --hashlimit-name portscan_log6 --hashlimit-mode srcip --hashlimit 1/sec --hashlimit-burst 1 \
                    -j LOG --log-prefix "portscan: " --log-level 6
        '';
        extraStopCommands = ''
          iptables -D nixos-fw-log-refuse -j ${portScanChain} || true
          iptables -F ${portScanChain} || true
          iptables -X ${portScanChain} || true

          ip6tables -D nixos-fw-log-refuse -j ${portScanChain} || true
          ip6tables -F ${portScanChain} || true
          ip6tables -X ${portScanChain} || true

          ipset destroy portscan4_track || true
          ipset destroy portscan4_count || true
          ipset destroy portscan6_track || true
          ipset destroy portscan6_count || true
        '';
      };

      services.fail2ban = {
        enable = mkDefault true;
        jails.portscan = {
          filter.Definition = {
            failregex = ''^.*portscan: IN=\S+ OUT=\S* MAC=\S+ SRC=<HOST> DST=\S+.*$'';
            ignoreregex = "";
          };
          settings = {
            banaction = mkDefault "%(banaction_allports)s";
            protocol = mkDefault "all";
            journalmatch = mkDefault "_TRANSPORT=kernel";
            findtime = mkDefault (toString portScan.findtime);
            maxretry = mkDefault 1;
          };
        };
      };
    })

    (mkIf cfg.knotInactiveClients.enable {
      services.fail2ban = {
        enable = mkDefault true;
        jails.knot-inactive-clients = {
          filter.Definition = {
            failregex = "^.*notice: TCP, terminated inactive client, address <HOST>@.*$";
            ignoreregex = "";
          };
          settings = {
            banaction = mkDefault "%(banaction_allports)s";
            protocol = mkDefault "all";
            journalmatch = mkDefault "_SYSTEMD_UNIT=knot.service";
            findtime = mkDefault "30m";
            maxretry = mkDefault 30;
          };
        };
      };
    })
  ];
}
