_self: super: {
  protoc-gen-transform = super.buildGoModule {
    name = "protoc-gen-transform";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-transform";
      rev = "31eb79ddc660347b2647a53dbf6942773bf14cf7";
      hash = "sha256-+Lh2hwQ+kS+6uIEgotSK8IA2TtGr7E5M6zE6WQiBvps=";
    };
    vendorHash = "sha256-7Ss+CjgnFW84U+LqA2NRe0Y7uzkGNowDv84b14nHPMo=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
