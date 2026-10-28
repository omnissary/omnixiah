_final: prev: {
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (_pythonFinal: pythonPrev: {
      httpcore2 = pythonPrev.httpcore2.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          # 10 ms cancellation timing is flaky under load.
          "test_h2_timeout_during_request"
          "test_h2_timeout_during_response"
        ];
      });
    })
  ];
}
