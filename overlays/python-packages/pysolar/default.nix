{
  buildPythonPackage,
  fetchPypi,
  numpy,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "pysolar";
  version = "0.13";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-BZE3QGlOS7KvhBLeP6J4wENbOxWyl1yOOGJfxO7R/Ww=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [ numpy ];

  pythonImportsCheck = [ "pysolar" ];
}
