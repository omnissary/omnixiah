_self: super: {
  athens = super.athens.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./athens-protocol.patch ];
  });
}
