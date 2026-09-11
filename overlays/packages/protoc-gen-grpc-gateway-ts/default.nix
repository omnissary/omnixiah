_self: super: {
  protoc-gen-grpc-gateway-ts = super.buildGoModule {
    name = "protoc-gen-grpc-gateway-ts";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-grpc-gateway-ts";
      rev = "cc7cfcdace92c3c012dd7bdff2ed32cee9b2a566";
      hash = "sha256-rvJkY567L8RzqYQHSmElxO/k8zBXTKS5W0lJDxom0Co=";
    };
    vendorHash = "sha256-gaUZXUrymmkDmsRfoTyVViF2ZFN92cNy24ZjWZy0ATs=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
