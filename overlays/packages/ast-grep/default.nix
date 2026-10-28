_final: prev: {
  ast-grep = prev.ast-grep.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      # The builder filesystem rejects deliberately invalid UTF-8 filenames.
      "--skip=test_scan_invalid_rule_id"
    ];
  });
}
