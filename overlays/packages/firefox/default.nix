_self: super:
let
  inherit (builtins) map;
  inherit (super.lib)
    hasPrefix
    replaceStrings
    ;

  thinLto =
    pkg:
    pkg.overrideAttrs (old: {
      configureFlags = map (
        flag:
        if hasPrefix "--enable-lto=" flag then
          replaceStrings [ "cross,full" "full" ] [ "cross,thin" "thin" ] flag
        else
          flag
      ) (old.configureFlags or [ ]);
    });
in
{
  firefox = thinLto super.firefox;
  firefox-unwrapped = thinLto super.firefox-unwrapped;
  thunderbird = thinLto super.thunderbird;
  thunderbird-unwrapped = thinLto super.thunderbird-unwrapped;
}
