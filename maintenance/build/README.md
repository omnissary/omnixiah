# Build input overrides

`just build` wraps `nix build`. With no target, Nix builds this flake's default
package, the MicroVM runner. Arguments are forwarded individually:

```sh
just build --dry-run
just build .#microvm --no-link
just build .#checks.x86_64-linux.maintenance-build
```

To fetch mirrored inputs from GitHub, create `.input-overrides.json` in the
repository root:

```json
{
  "git.tatikoma.dev": "github:omnissary"
}
```

The file is ignored by Git. Without it, the build uses the normal inputs.
An empty object also disables replacements.

Each matching source URL becomes `github:omnissary/NAME/REV`, retaining the
locked commit and any subdirectory. The original owner is ignored. For example,
`https://git.tatikoma.dev/omnixiah/sops-nix/archive/omnixiah.tar.gz` uses
`github:omnissary/sops-nix/REV`. The GitHub mirror must contain that commit.

The helper walks `flake.lock` and passes temporary `--override-input` arguments
for direct and transitive input paths, including non-flake sources. Shared nodes
are overridden at every independent path; `follows` edges retain their targets.
Inputs on other hosts keep their normal sources. Missing locked revisions cause
an error instead of selecting a different commit.

Overrides apply only to `just build` and use this repository's input graph.
Neither `flake.nix` nor `flake.lock` is rewritten. When building an unrelated
flake, disable the rules or supply overrides appropriate to its input graph.
