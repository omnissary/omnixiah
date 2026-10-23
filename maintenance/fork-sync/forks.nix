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
  };

  disko = mkFork {
    directory = "disko";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nix-community/disko";
  };

  flake-parts = mkFork {
    directory = "flake-parts";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/hercules-ci/flake-parts";
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

  nix = mkFork {
    directory = "nix";
    upstreamBranch = "master";
    upstreamUrl = "https://github.com/nixOS/nix";
  };

  nixos-anywhere = mkFork {
    directory = "nixos-anywhere";
    upstreamBranch = "main";
    upstreamUrl = "https://github.com/nix-community/nixos-anywhere";
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

  xlibre = mkFork {
    directory = "xlibre";
    upstreamBranch = "main";
    upstreamUrl = "https://codeberg.org/takagemacoed/xlibre-overlay";
  };
}
