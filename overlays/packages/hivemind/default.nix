_self: super: {
  hivemind = super.hivemind.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (super.fetchurl {
        url = "https://git.tatikoma.dev/corpix/hivemind/commit/e561020e2229763be2f17475929a79e49a0f129d.patch";
        hash = "sha256-Jo75rZCnnsba7q5LiFteIuBwM301Q4fI9yBNRhbTfMo=";
      })
    ];
  });
}
