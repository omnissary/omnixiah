{
  buildPythonPackage,
  click,
  fetchPypi,
  ladybug-geometry,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "ladybug-core";
  version = "0.44.52";
  pyproject = true;

  src = fetchPypi {
    pname = "ladybug_core";
    inherit version;
    hash = "sha256-m+eORWjIBFEm6s3SeJbmBNKPr8XbX5Kc5KfU2TUfZrU=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    click
    ladybug-geometry
  ];

  pythonRelaxDeps = [ "click" ];

  pythonImportsCheck = [ "ladybug" ];
}
