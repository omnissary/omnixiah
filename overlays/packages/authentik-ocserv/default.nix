_self: super: {
  authentik-ocserv = super.callPackage (
    { buildGoModule, fetchFromGitea }:
    buildGoModule rec {
      name = "authentik-ocserv";
      version = "1.0.0";
      src = fetchFromGitea {
        domain = "git.tatikoma.dev";
        owner = "corpix";
        repo = name;
        rev = version;
        hash = "sha256-RQyQ6xl2VrekCBEfkSut/SVcmfHKg+brRcdYy8T8aH0=";
      };
      vendorHash = null;
    }
  ) { };
}
