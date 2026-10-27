_final: prev: {
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (_pythonFinal: pythonPrev: {
      uvloop = pythonPrev.uvloop.overridePythonAttrs (old: {
        disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
          # Flaky callback ordering: https://github.com/NixOS/nixpkgs/issues/497277
          "tests/test_process.py::Test_UV_Process_Delayed::test_process_delayed_stdio__not_paused__no_stdin"
        ];
      });
    })
  ];
}
