_self: super: {
  awesome = super.awesome.override {
    gtk3Support = true;
  };
}
