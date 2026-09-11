_self: super: {
  prometheus-yggdrasil-exporter = super.callPackage (
    { buildGoModule, fetchFromGitea, ... }:
    let
      version = "0712f43ea5d8675e07b55ee3b989b9b7c197b8b2";
      src = fetchFromGitea {
        domain = "git.tatikoma.dev";
        owner = "corpix";
        repo = "prometheus-yggdrasil-exporter";
        rev = version;
        hash = "sha256-rpUv8z+mw1Qxi1SvCpw0heN7zlp95cw/k24W94nox7s=";
      };
    in
    buildGoModule {
      name = "prometheus-yggdrasil-exporter";
      inherit src;
      vendorHash = null;
      ldflags = [
        "-s"
        "-w"
      ];
      doCheck = false;
    }
  ) { };
}
