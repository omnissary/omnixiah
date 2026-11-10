{ pkgs }:
pkgs.runCommand "omnixiah-build-overrides-test" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python3 ${./test.py} ${../build}
  touch $out
''
