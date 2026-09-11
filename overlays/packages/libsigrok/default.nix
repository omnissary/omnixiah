_self: super: {
  libsigrok = super.libsigrok.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./libsigrok-sipeed-slogiclite8.patch ];
  });
}
