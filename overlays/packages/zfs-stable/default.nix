_self: super: {
  zfsStable = super.zfs.override {
    enableMail = true;
  };
}
