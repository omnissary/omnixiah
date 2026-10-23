{ pkgs }:
pkgs.runCommand "omnixiah-fork-sync-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.jq
    ];
  }
  ''
    cp -R ${../.} source
    chmod -R u+w source
    patchShebangs source
    source/tests/sync.sh source/sync
    touch $out
  ''
