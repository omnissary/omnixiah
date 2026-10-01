{
  buildPythonPackage,
  fetchPypi,
  ladybug-core,
  numpy,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "ladybug-radiance";
  version = "0.2.11";
  pyproject = true;

  src = fetchPypi {
    pname = "ladybug_radiance";
    inherit version;
    hash = "sha256-wWB30zp/s6kGXoVh+u9oWdeorWxeK0oG6nYqXHx3HB8=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    ladybug-core
    numpy
  ];

  pythonImportsCheck = [ "ladybug_radiance" ];
}
