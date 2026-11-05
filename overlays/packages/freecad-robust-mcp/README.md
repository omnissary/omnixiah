# FreeCAD Robust MCP

The overlay provides two packages from upstream's stable 0.6.2 release:

- `freecad-robust-mcp`: the external MCP server, with the `freecad-mcp` command.
- `freecad-robust-mcp-workbench`: the bridge loaded inside FreeCAD.

The server uses `python3Packages.mcp_1` because this release imports the SDK's
`mcp.server.fastmcp` API.

Install both in a NixOS or Home Manager package list using the omnixiah overlay:

```nix
[
  pkgs.freecad-robust-mcp
  (pkgs.freecad.customize {
    modules = [ pkgs.freecad-robust-mcp-workbench ];
  })
]
```

The same `customize` call works with `pkgs.freecad-git`.

Launch the customized FreeCAD, select the **Robust MCP Bridge** workbench, and
start the bridge with its toolbar button. Configure the MCP client to launch
`freecad-mcp` with `FREECAD_MODE=xmlrpc`. The default bridge address is
`localhost:9875`. The bridge must be running before the client connects.

For example, in an MCP client supporting this JSON configuration:

```json
{
  "mcpServers": {
    "freecad": {
      "command": "freecad-mcp",
      "env": {
        "FREECAD_MODE": "xmlrpc"
      }
    }
  }
}
```

Use the absolute store path `${pkgs.freecad-robust-mcp}/bin/freecad-mcp` when
generating client configuration with Nix to avoid depending on the client's PATH.

From the omnixiah checkout, build both packages with:

```sh
nix build .#pkgs.x86_64-linux.freecad-robust-mcp .#pkgs.x86_64-linux.freecad-robust-mcp-workbench
```
