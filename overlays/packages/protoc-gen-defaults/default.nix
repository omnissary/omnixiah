_self: super: {
  protoc-gen-defaults = super.buildGoModule {
    name = "protoc-gen-defaults";

    src = super.fetchFromGitHub {
      owner = "linka-cloud";
      repo = "protoc-gen-defaults";
      rev = "1b81061d20ceced5dd107b1020802817e23b245d";
      hash = "sha256-ApXyNEqRKtSbaDEI03nxTeuAbIQ1oAlrLAk0Igy8Z/M=";
    };
    vendorHash = "sha256-XWMCBRcSQiU+KjjIPnwsa6fP6Hp0q0NORoH/5ZJTM9w=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;

    postInstall = ''
      mkdir -p $out/usr/share/proto
      cp -r defaults $out/usr/share/proto/protoc-gen-defaults
    '';
  };
}
