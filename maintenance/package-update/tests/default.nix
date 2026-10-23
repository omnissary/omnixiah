{ pkgs }:
pkgs.runCommand "omnixiah-package-update-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.git
      pkgs.jq
      pkgs.util-linux
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    cp -R ${../..} source
    chmod -R u+w source
    patchShebangs source
    source/package-update/tests/update.sh source/package-update/update
    touch $out
  ''
