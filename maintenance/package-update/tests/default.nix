{ pkgs }:
pkgs.runCommand "omnixiah-package-update-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.git
      pkgs.jq
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${pkgs.bash}/bin/bash ${./update.sh} ${../.}/update
    touch $out
  ''
