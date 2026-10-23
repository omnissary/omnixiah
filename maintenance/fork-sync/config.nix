let
  inherit (builtins)
    all
    elem
    isAttrs
    isList
    isString
    map
    mapAttrs
    match
    throw
    ;

  forks = import ./forks.nix;

  require =
    condition: message: value:
    if condition then value else throw message;

  command =
    name: value:
    require (
      isList value && value != [ ] && all isString value
    ) "fork ${name}: commands must be non-empty lists of strings" value;

  remote =
    name: kind: value:
    require (isAttrs value) "fork ${name}: ${kind} must be an attribute set" (
      {
        remote =
          require (isString value.remote) "fork ${name}: ${kind}.remote must be a string"
            value.remote;
        branch =
          require (isString value.branch) "fork ${name}: ${kind}.branch must be a string"
            value.branch;
      }
      // (
        if value ? url then
          {
            url = require (isString value.url) "fork ${name}: ${kind}.url must be a string" value.url;
          }
        else
          { }
      )
    );

  update =
    name: value:
    let
      updateType = value.type or "flake";
      policy = value.policy or "requested";
      inputs = value.inputs or "all";
    in
    require (isAttrs value) "fork ${name}: update must be an attribute set" (
      require
        (elem updateType [
          "command"
          "flake"
        ])
        "fork ${name}: unsupported update type ${updateType}"
        (
          require
            (elem policy [
              "always"
              "never"
              "requested"
            ])
            "fork ${name}: unsupported update policy ${policy}"
            (
              require (inputs == "all" || (isList inputs && all isString inputs))
                "fork ${name}: update.inputs must be \"all\" or a list of strings"
                (
                  {
                    type = updateType;
                    inherit inputs policy;
                    commitMessage =
                      require (isString (value.commitMessage or "update generated files"))
                        "fork ${name}: update.commitMessage must be a string"
                        (value.commitMessage or "update generated files");
                  }
                  // (
                    if updateType == "command" then
                      {
                        argv = command name value.argv;
                      }
                    else
                      { }
                  )
                )
            )
        )
    );

  fork =
    name: value:
    require (isAttrs value) "fork ${name}: definition must be an attribute set" {
      inherit name;
      directory = require (
        isString value.directory && match "[A-Za-z0-9._-]+" value.directory != null
      ) "fork ${name}: directory must name a sibling repository" value.directory;
      branch = require (isString value.branch) "fork ${name}: branch must be a string" value.branch;
      upstream = remote name "upstream" value.upstream;
      destination = remote name "destination" value.destination;
      update = update name (value.update or { });
      format = map (command name) (value.format or [ ]);
      checks = map (command name) (value.checks or [ ]);
    };
in
mapAttrs fork forks
