{ config, lib, ... }:

let
  inherit (builtins) all;
  inherit (lib) mkAfter mkDefault;

  validUsers = users: users == [ ] || users == [ "root" ];
  validGroups = groups: groups == [ ] || groups == [ "wheel" ];
  validUserGroups = all (
    rule: validUsers (rule.users or [ ]) && validGroups (rule.groups or [ ])
  ) config.security.sudo.extraRules;
in

{
  security.sudo.wheelNeedsPassword = mkDefault true;
  security.sudo.execWheelOnly = mkDefault true;
  security.sudo.extraConfig = mkAfter ''
    Defaults lecture = never
  '';

  assertions = [
    {
      assertion = config.security.sudo.execWheelOnly -> validUserGroups;
      message = "Some security.sudo.extraRules entries refer to users other than root or groups other than wheel.";
    }
  ];
}
