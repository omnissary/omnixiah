_self: super: {
  ndfs = super.callPackage (
    { fetchgit, buildGoModule, ... }:
    buildGoModule rec {
      name = "ndfs";
      rev = "0010f62078d96774f02ec11aa2aa573afccde2b4";
      src = fetchgit {
        inherit rev;
        url = "https://git.tatikoma.dev/corpix/ndfs";
        hash = "sha256-BMQYePvjLYTWIY2fCN+v5kXB68SJS89tQTIPjrVRf3g=";
      };
      vendorHash = null;
    }
  ) { };
}
