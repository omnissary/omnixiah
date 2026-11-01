let
  inherit (builtins) attrValues genericClosure;

  inputNode = flake: {
    key = flake.outPath;
    inherit flake;
  };
in
{
  inputSources =
    flake:
    map (node: node.flake.outPath) (genericClosure {
      startSet = [ (inputNode flake) ];
      operator = node: map inputNode (attrValues (node.flake.inputs or { }));
    });
}
