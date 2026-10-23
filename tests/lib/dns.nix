{
  pkgs,
  self,
}:

let
  inherit (builtins) isAttrs isFunction;
  dns = self.lib.dns;
in

if isFunction dns.evalZone && isAttrs dns.combinators && isAttrs dns.types then
  pkgs.writeText "omnixiah-dns-lib" "OK"
else
  throw "DNS library export is incomplete"
