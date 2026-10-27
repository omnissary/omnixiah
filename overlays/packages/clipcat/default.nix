_final: prev: {
  clipcat = prev.clipcat.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Cargo.toml \
        --replace-fail 'elided_lifetimes_in_associated_constant = "deny"' "" \
        --replace-fail 'no_mangle_generic_items                 = "deny"' "" \
        --replace-fail 'repr_transparent_non_zst_fields         = "deny"' ""
    '';
  });
}
