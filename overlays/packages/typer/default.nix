_final: prev: {
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (_pythonFinal: pythonPrev: {
      typer = pythonPrev.typer.overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace tests/test_types_file.py \
            --replace-fail 'file_path = tmp_path / "cannot-open.txt"' 'file_path = Path("cannot-open.txt")'
        '';
      });
    })
  ];
}
