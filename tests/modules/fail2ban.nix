{
  inputs,
  pkgs,
  self,
  system,
}:

let
  inherit (builtins) attrNames;
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    concatStringsSep
    elem
    hasInfix
    nixosSystem
    optionals
    ;

  cfg =
    (nixosSystem {
      inherit system;
      specialArgs = {
        inherit self;
      };
      modules = [
        self.profiles.base
        {
          networking = {
            hostName = "fail2ban-test";
            firewall.backend = "iptables";
          };

          services.fail2ban = {
            mitigations = {
              portScan = {
                enable = true;
                ignoreInterfaces = [ "lo" ];
                findtime = 60;
                maxPorts = 4;
              };
              knotInactiveClients.enable = true;
            };
            jails.portscan.settings.bantime = "12h";
          };
        }
      ];
    }).config;

  portScanJail = cfg.services.fail2ban.jails.portscan;
  knotInactiveClientsJail = cfg.services.fail2ban.jails.knot-inactive-clients;
  firewallCommands = cfg.networking.firewall.extraCommands;

  errors =
    optionals (!cfg.services.fail2ban.enable) [
      "enabling a mitigation does not enable fail2ban"
    ]
    ++
      optionals
        (
          attrNames cfg.services.fail2ban.mitigations != [
            "knotInactiveClients"
            "portScan"
          ]
        )
        [
          "unexpected fail2ban mitigation options"
        ]
    ++ optionals (portScanJail.settings.findtime != "60") [
      "port scan jail findtime does not follow the mitigation"
    ]
    ++ optionals (portScanJail.settings.maxretry != 1) [
      "port scan jail does not ban on the first detector event"
    ]
    ++ optionals (portScanJail.settings.bantime != "12h") [
      "standard jail settings cannot override port scan defaults"
    ]
    ++ optionals (knotInactiveClientsJail.settings.findtime != "30m") [
      "Knot inactive client jail has an unexpected findtime"
    ]
    ++ optionals (!hasInfix "timeout 60 counters" firewallCommands) [
      "port scan counters do not use the configured findtime"
    ]
    ++ optionals (!hasInfix "--packets-gt 4" firewallCommands) [
      "port scan detector does not use the configured port limit"
    ]
    ++ optionals (!hasInfix "-i lo -j RETURN" firewallCommands) [
      "ignored interfaces are not excluded from port scan detection"
    ]
    ++ optionals (!(elem pkgs.ipset cfg.networking.firewall.extraPackages)) [
      "ipset is not available to the firewall"
    ];
in

if errors != [ ] then
  throw "fail2ban module test failed:\n${concatStringsSep "\n" errors}"
else
  pkgs.writeText "omnixiah-fail2ban-module" ''
    ${portScanJail.filter.Definition.failregex}
    ${knotInactiveClientsJail.filter.Definition.failregex}
  ''
