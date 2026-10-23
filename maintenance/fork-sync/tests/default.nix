{ pkgs }:
pkgs.runCommand "omnixiah-fork-sync-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.jq
      pkgs.util-linux
    ];
  }
  ''
    cp -R ${../..} source
    chmod -R u+w source
    patchShebangs source
    source/fork-sync/tests/sync.sh source/fork-sync/sync
    touch $out
  ''
