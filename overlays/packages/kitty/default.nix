_self: super: {
  kitty = super.kitty.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./kitty-silence.patch
      # (super.fetchurl {
      #   url = "https://git.tatikoma.dev/corpix/kitty/commit/a352d1df198c35acca741e4b140ca07927c505e9.patch";
      #   hash = "sha256-lFzRKh2sEOzyMduMGNgM6dU7jBQjzVaRynM+7Mw3FAw=";
      # })
    ];
  });
}
