{
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "ladybug-geometry";
  version = "1.35.1";
  pyproject = true;

  src = fetchPypi {
    pname = "ladybug_geometry";
    inherit version;
    hash = "sha256-HxUozniUKEUA8WaCn2a4qb4qaD1Nm8g4vOC6I99EEBI=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  pythonImportsCheck = [ "ladybug_geometry" ];
  doCheck = false;
}
