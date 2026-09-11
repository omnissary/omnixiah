_self: super: {
  fensible = super.buildGoModule {
    name = "fensible";
    src = builtins.fetchTarball {
      url = "https://git.tatikoma.dev/corpix/fensible/archive/2c5fb0e6a60104ac79981307053294b2fa07f72e.tar.gz";
      sha256 = "sha256:02b8qihqcv97pa5v5kkfxv34xxg1zjy15d8nnnqaizkfcwka1wkj";
    };
    vendorHash = "sha256-TRTMmutqiWjWBhS/qOACh8j1FE4pe0FNhVPtUUjjU5k=";
  };
}
