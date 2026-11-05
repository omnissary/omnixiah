final: _prev:
let
  inherit (final) fetchFromGitHub python3Packages stdenvNoCC;
  inherit (final.lib) licenses platforms;
  inherit (python3Packages)
    buildPythonApplication
    hatchling
    hatch-vcs
    mcp_1
    pydantic
    pydantic-settings
    pytestCheckHook
    pytest-asyncio
    ;

  version = "0.6.2";
  src = fetchFromGitHub {
    owner = "spkane";
    repo = "freecad-addon-robust-mcp-server";
    tag = "robust-mcp-server-v${version}";
    hash = "sha256-CqErPT3VtZeyuoA7GWEY7dD1rzniWdD3H1BbbIdB49Y=";
  };

  meta = {
    homepage = "https://github.com/spkane/freecad-addon-robust-mcp-server";
    license = licenses.mit;
    platforms = platforms.all;
  };
in
{
  freecad-robust-mcp = buildPythonApplication {
    pname = "freecad-robust-mcp";
    inherit version src;
    pyproject = true;

    build-system = [
      hatchling
      hatch-vcs
    ];
    env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

    postPatch = ''
      substituteInPlace src/freecad_mcp/server.py \
        --replace-fail 'version("freecad-mcp")' 'version("freecad-robust-mcp")'
    '';

    dependencies = [
      mcp_1
      pydantic
      pydantic-settings
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-asyncio
    ];
    pytestFlags = [ "tests/unit" ];
    pythonImportsCheck = [ "freecad_mcp.server" ];

    meta = meta // {
      description = "MCP server for controlling FreeCAD through its Robust MCP Bridge";
      mainProgram = "freecad-mcp";
    };
  };

  freecad-robust-mcp-workbench = stdenvNoCC.mkDerivation {
    pname = "freecad-robust-mcp-workbench";
    inherit version src;

    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r addon/FreecadRobustMCPBridge/. "$out/"
      cp package.xml LICENSE "$out/"
      substituteInPlace "$out/package.xml" \
        --replace-fail 'addon/FreecadRobustMCPBridge/' ""
      runHook postInstall
    '';

    meta = meta // {
      description = "FreeCAD workbench providing the Robust MCP Bridge";
    };
  };
}
