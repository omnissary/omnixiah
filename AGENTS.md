# Repository Guidelines

## Project Structure & Module Organization

Omnixiah is a NixOS spin built around reusable NixOS profiles. The root `flake.nix` defines inputs, the overlaid `pkgs` package set, apps, checks, formatter, `profiles`, and `modules`. `modules/default.nix` enumerates every file next to it, so a new shared module such as `modules/tc.nix` is registered by dropping the file in. `profiles/` contains the base, debug, MicroVM, and QEMU profile modules. The MicroVM profile is instantiated for every supported Linux system and exposed as the runnable `microvm` package and app.

A directory is entered through its `default.nix`, and a file is named after what it is, never after the directory holding it: `modules/tc.nix`, not `modules/tc-module.nix`.

Three layers make up a system, and they must not be mixed:

- `modules/` declares options. Safe to import anywhere, including evaluations Omnixiah does not control.
- `profiles/base.nix` imports `modules/` and sets the distribution defaults. It declares the read-only marker `omnixiah.base` and must never touch `nixpkgs.*`.
- The nixpkgs instance (`nixpkgs.config` and `nixpkgs.overlays`) belongs to whoever constructs the system, and is applied by `lib.nixosSystem` alone.

Two entry points apply the base profile, and nothing else does:

- `lib.nixosSystem` passes the base and nixpkgs profiles as `extraModules`, so they survive `specialisation` with `inheritParentConfig = false`.
- `pkgs.omnixiah.runNixOSTest` passes the base profile as test `defaults`, reaching both nodes and containers. Nodes keep the host package set read-only; a consumer that configures `nixpkgs.*` inside a node sets `node.pkgsReadOnly = false` itself.

Any other evaluation -- a raw `import "${pkgs.path}/nixos"`, a `containers.<name>.config` -- gets no base profile and must import `profiles.base` explicitly. `tests/coverage.nix` asserts the entry points still carry it.

Use neighboring repositories as context only: `../infra/flake.nix` supplies the corpix `nixpkgs` input, `../microvm` is the MicroVM implementation, and `../nixpkgs` is useful for source inspection. Flake inputs must use remote URLs so CI does not depend on local paths.

Offline evaluation must work on installed systems. Flake input sources are part of the system configuration and must survive garbage collection. Omnixiah's base profile sets `system.extraDependencies = inputSources inputs.self;`, importing `inputSources` from `lib/flakes.nix`. Consumers set `system.extraDependencies = inputs.omnixiah.lib.flakes.inputSources self;` for their own root flake. Keep the complete input graph in this option when changing flake inputs or legacy Nix entry points.

## Build, Test, and Development Commands

Use the lowercase `justfile` as the command surface.

- `just profiles`: list profiles from `.#profiles`.
- `just eval`: evaluate the MicroVM configuration hostname.
- `just build`: build the MicroVM runner.
- `just run`: run the MicroVM profile.
- `just lint`: run `nix flake check --show-trace`.
- `just test`: run all module tests from `.#lib.tests`.
- `just fmt`: run treefmt through `nix fmt`.

Direct Nix commands are acceptable for debugging, for example `nix build .#nixosConfigurations.microvm-x86_64-linux.config.microvm.declaredRunner`.

## Coding Style & Naming Conventions

Use two-space indentation for Nix files. Use lower camel case for Nix option-style names and kebab-case for files or directories. Place profile implementations in `profiles/<name>.nix`, register them in `flake.nix`, and construct systems with `lib.nixosSystem` so they receive the base profile. Order-sensitive list options such as `boot.kernelParams` must pin their order with `mkBefore` or `mkAfter` instead of relying on module evaluation order. Do not shadow generic Nixpkgs builders; Omnixiah-specific builders live under the `pkgs.omnixiah` namespace provided by `overlays/default.nix`.

In Nix files, bring helpers into scope with local inherit bindings instead of using qualified calls such as `lib.mkDefault`: `inherit (lib) mkDefault optionalAttrs ...;` and `inherit (builtins) attrNames filter listToAttrs ...;`. Keep each inherit list limited to names used in that file. Keep Nix prelude names such as `map`, `throw`, and `import` direct instead of inheriting them. Do not add explanatory code comments; improve structure or Markdown documentation instead.

No shortcuts: follow the architecture, keep changes cohesive, and chase failures to their cause. Keep insecure or local-only VM behavior out of shared profiles.

## Testing Guidelines

Tests under `tests/modules/` should exercise module evaluation or deterministic VM behavior for changed modules. Build VM tests with `pkgs.omnixiah.runNixOSTest` and evaluation tests with `lib.nixosSystem`; neither needs an explicit `profiles.base` import. Tests do not have internet access; assert generated configuration, evaluated options, local units, or local network state. Every profile should evaluate with `just eval <profile>`. Before submitting changes, run `just fmt`, `just test`, and `just lint`. CI in `.gitea/workflows/ci.yaml` runs `just lint` and `just test`.

## Commit & Pull Request Guidelines

The current history uses concise imperative messages (`init`). Continue with short present-tense commits such as `simplify microvm profile`.

Pull requests should describe the changed profile or module, list commands run, and call out host assumptions such as KVM support.
