_final: prev: {
  just = prev.just.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=non_unicode::warn_for_non_unicode_invocation_directory"
      "--skip=non_unicode::warn_for_non_unicode_justfile_path"
    ];
  });
}
