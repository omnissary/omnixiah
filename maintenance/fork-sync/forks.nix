let
  mkFork =
    {
      directory,
      upstreamBranch,
      upstreamUrl,
      branch ? "omnixiah",
      destinationRemote ? "tatikoma",
      destinationBranch ? branch,
      checks ? [
        [
          "nix"
          "flake"
          "check"
          "--no-build"
          "--show-trace"
        ]
      ],
    }:
    {
      inherit
        branch
        checks
        directory
        ;

      upstream = {
        remote = "upstream";
        branch = upstreamBranch;
        url = upstreamUrl;
      };

      destination = {
        remote = destinationRemote;
        branch = destinationBranch;
      };

      update = {
        type = "flake";
        policy = "requested";
        inputs = "all";
        commitMessage = "update flake inputs";
      };

      format = [ ];
    };
in
{
  authentik = mkFork {
    directory = "authentik";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/nix-community/authentik-nix";
    checks = [
      [
        "nix"
        "eval"
        "--raw"
        ".#packages.x86_64-linux.gopkgs.drvPath"
      ]
      [
        "nix"
        "eval"
        "--raw"
        ".#checks.x86_64-linux.default.name"
      ]
    ];
  };

  disko = mkFork {
    directory = "disko";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nix-community/disko";
    checks = [
      [
        "nix"
        "eval"
        "--raw"
        ".#checks.x86_64-linux.disko-install.name"
      ]
      [
        "nix"
        "eval"
        "--json"
        ".#nixosModules"
        "--apply"
        "builtins.attrNames"
      ]
    ];
  };

  flake-parts = mkFork {
    directory = "flake-parts";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/hercules-ci/flake-parts";
    checks = [
      [
        "nix"
        "eval"
        "--json"
        ".#flakeModules"
        "--apply"
        "builtins.attrNames"
      ]
      [
        "nix"
        "eval"
        "--json"
        ".#templates"
        "--apply"
        "builtins.attrNames"
      ]
    ];
  };

  flake-utils = mkFork {
    directory = "flake-utils";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/numtide/flake-utils";
  };

  home-manager = mkFork {
    directory = "home-manager";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nix-community/home-manager";
  };

  mailserver = mkFork {
    directory = "mailserver";
    upstreamBranch = "main";
    upstreamUrl = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver.git";
  };

  microvm = mkFork {
    directory = "microvm";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/microvm-nix/microvm.nix";
  };

  nix = mkFork {
    directory = "nix";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nixOS/nix";
    checks = [
      [
        "nix"
        "eval"
        "--raw"
        ".#packages.x86_64-linux.nix.drvPath"
      ]
      [
        "nix"
        "eval"
        "--json"
        ".#checks.x86_64-linux"
        "--apply"
        "builtins.attrNames"
      ]
    ];
  };

  nixos-anywhere = mkFork {
    directory = "nixos-anywhere";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/nix-community/nixos-anywhere";
    checks = [
      [
        "nix"
        "eval"
        "--raw"
        ".#packages.x86_64-linux.nixos-anywhere.drvPath"
      ]
      [
        "nix"
        "eval"
        "--json"
        ".#checks.x86_64-linux"
        "--apply"
        "builtins.attrNames"
      ]
    ];
  };

  nixpkgs = mkFork {
    directory = "nixpkgs";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nixos/nixpkgs";
  };

  sops = mkFork {
    directory = "sops-nix";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/mic92/sops-nix";
  };

  systems = mkFork {
    directory = "systems";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/nix-systems/default";
  };

  treefmt = mkFork {
    directory = "treefmt";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/numtide/treefmt-nix";
  };

  xlibre = mkFork {
    directory = "xlibre";
    upstreamBranch = "main";
    upstreamUrl = "https://codeberg.org/takagemacoed/xlibre-overlay";
  };
}
