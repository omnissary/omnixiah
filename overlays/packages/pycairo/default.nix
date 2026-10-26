# pycairo's test_fspaths asserts that cairo rejects filenames the platform
# cannot represent. Filesystems that accept them make it fail, which takes out
# every consumer: pygobject, bluez, brltty and so the NixOS test runner.
# Disabling the one test keeps the remaining suite in place.
_self: super: {
  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (_pythonFinal: pythonPrev: {
      pycairo = pythonPrev.pycairo.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [
          "test_fspaths"
        ];
      });
    })
  ];
}
