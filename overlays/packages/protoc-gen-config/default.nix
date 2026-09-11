_self: super: {
  protoc-gen-config = super.buildGoModule {
    name = "protoc-gen-config";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-config";
      rev = "645fb21057ac5e856dc63a8576b0c2fd29a440c0";
      hash = "sha256-WTSvpZBE96pLUQhj/429ANC86shkfExjPmxVdqyq3bc=";
    };
    vendorHash = "sha256-NsWCYAWS8zgX+Bx+OgtFCuB503NihCmVjDXQ8skSz8c=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
