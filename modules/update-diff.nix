{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    versionAtLeast
    ;

  cfg = config.modules.update-diff;
in

{
  options.modules.update-diff = {
    enable = mkEnableOption "show package diff when updating" // {
      default = true;
    };

    command = mkOption {
      type = types.singleLineStr;
      default =
        if versionAtLeast (pkgs.dix.version or "0") "1.4.2" then
          "${getExe pkgs.dix} --force-correctness"
        else
          "${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff";
      defaultText = literalExpression ''"''${getExe pkgs.dix} --force-correctness"'';
      description = "Diff command.";
    };

    text = mkOption {
      type = types.str;
      description = "Diff script snippet.";
    };
  };

  config = {
    modules.update-diff.text = ''
      if [[ -e /run/current-system && -e "''${incoming-}" ]]; then
        echo "--- diff to current-system"
        ${cfg.command} /run/current-system "''${incoming-}"
        echo "---"
      fi
    '';

    system.preSwitchChecks = mkIf cfg.enable {
      update-diff = ''
        incoming="''${1-}"
        ${cfg.text}
      '';
    };
  };
}
