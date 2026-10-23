let
  mkFork =
    {
      directory,
      upstreamRemote,
      upstreamBranch,
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
        remote = upstreamRemote;
        branch = upstreamBranch;
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
    upstreamRemote = "tatikoma";
    upstreamBranch = "main";
  };

  disko = mkFork {
    directory = "disko";
    upstreamRemote = "origin";
    upstreamBranch = "master";
  };

  flake-parts = mkFork {
    directory = "flake-parts";
    upstreamRemote = "origin";
    upstreamBranch = "main";
  };

  home-manager = mkFork {
    directory = "home-manager";
    upstreamRemote = "origin";
    upstreamBranch = "master";
  };

  mailserver = mkFork {
    directory = "mailserver";
    upstreamRemote = "tatikoma";
    upstreamBranch = "master";
  };

  nix = mkFork {
    directory = "nix";
    upstreamRemote = "origin";
    upstreamBranch = "master";
  };

  nixos-anywhere = mkFork {
    directory = "nixos-anywhere";
    upstreamRemote = "upstream";
    upstreamBranch = "main";
  };

  nixpkgs = mkFork {
    directory = "nixpkgs";
    upstreamRemote = "origin";
    upstreamBranch = "master";
  };

  sops = mkFork {
    directory = "sops-nix";
    upstreamRemote = "origin";
    upstreamBranch = "master";
  };

  xlibre = mkFork {
    directory = "xlibre";
    upstreamRemote = "origin";
    upstreamBranch = "main";
  };
}
