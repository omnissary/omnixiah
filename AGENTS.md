# Repository Guidelines

## Project Structure & Module Organization

Omnixiah is a NixOS spin built around reusable NixOS profiles. The root `flake.nix` defines inputs, the overlaid `pkgs` package set, apps, checks, formatter, `profiles`, and `modules`. `modules/` holds shared modules such as `modules/firewall.nix`, `modules/nix.nix`, and `modules/tc.nix`. `profiles/` contains the base, MicroVM, and QEMU profile modules. The MicroVM profile is instantiated for every supported Linux system and exposed as the runnable `microvm` package and app.

Use neighboring repositories as context only: `../infra/flake.nix` supplies the corpix `nixpkgs` input, `../microvm` is the MicroVM implementation, and `../nixpkgs` is useful for source inspection. Flake inputs must use remote URLs so CI does not depend on local paths.

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

Use two-space indentation for Nix files. Use lower camel case for Nix option-style names and kebab-case for files or directories. Place profile implementations in `profiles/<name>.nix`, register them in `flake.nix`, and compose every specialized profile with the base profile.

Prefer local inherit bindings over repeated qualified calls: `inherit (lib) mkDefault optionalAttrs ...;` and `inherit (builtins) attrNames filter listToAttrs ...;`. Keep Nix prelude names such as `map`, `throw`, and `import` direct instead of inheriting them. Do not add explanatory code comments; improve structure or Markdown documentation instead.

No shortcuts: follow the architecture, keep changes cohesive, and chase failures to their cause. Keep insecure or local-only VM behavior out of shared profiles.

## Testing Guidelines

Tests under `tests/modules/` should exercise module evaluation or deterministic VM behavior for changed modules. Tests do not have internet access; assert generated configuration, evaluated options, local units, or local network state. Every profile should evaluate with `just eval <profile>`. Before submitting changes, run `just fmt`, `just test`, and `just lint`. CI in `.gitea/workflows/ci.yaml` runs `just lint` and `just test`.

## Commit & Pull Request Guidelines

The current history uses concise imperative messages (`init`). Continue with short present-tense commits such as `simplify microvm profile`.

Pull requests should describe the changed profile or module, list commands run, and call out host assumptions such as KVM support.
