# Repository Guidelines

## Project Structure & Module Organization

Omnixiah is a NixOS spin built around MicroVM profiles. The root `flake.nix` defines inputs, packages, apps, checks, formatter, `nixosModules`, and metadata. `lib/microvm.nix` exports `mkMicrovmProfile`. `modules/` holds shared modules such as `modules/firewall.nix`, `modules/nix.nix`, and `modules/tc.nix`. `profiles/default.nix` is the registry; `profiles/vm.nix` contains VM-only login defaults.

Use neighboring repositories as context: `../infra/flake.nix` supplies the corpix `nixpkgs` input, `../microvm` is the MicroVM implementation, and `../nixpkgs` is useful for source inspection.

## Build, Test, and Development Commands

Use the lowercase `justfile` as the command surface.

- `just profiles`: list profiles from `.#lib.profiles`.
- `just eval minimal`: evaluate the minimal profile hostname.
- `just build minimal`: build the MicroVM runner.
- `just run minimal`: run the MicroVM profile.
- `just lint`: run `nix flake check --show-trace`.
- `just test`: run all module tests from `.#lib.tests`.
- `just fmt`: run treefmt through `nix fmt`.

Direct Nix commands are acceptable for debugging, for example `nix build .#packages.x86_64-linux.minimal`.

## Coding Style & Naming Conventions

Use two-space indentation for Nix files. Use lower camel case for Nix option-style names and kebab-case for files or directories. Add profiles by registering them in `profiles/default.nix` and placing implementation in `profiles/<name>.nix`.

Prefer local inherit bindings over repeated qualified calls: `inherit (lib) mkDefault optionalAttrs ...;` and `inherit (builtins) attrNames filter listToAttrs ...;`. Keep Nix prelude names such as `map`, `throw`, and `import` direct instead of inheriting them. Do not add explanatory code comments; improve structure or Markdown documentation instead.

No shortcuts: follow the architecture, keep changes cohesive, and chase failures to their cause. Keep insecure or local-only VM behavior out of shared modules; root autologin and no-password login belong in `profiles/vm.nix`, not `modules/base.nix`.

## Testing Guidelines

Tests under `tests/modules/` should exercise module evaluation or deterministic VM behavior for changed modules. Tests do not have internet access; assert generated configuration, evaluated options, local units, or local network state. Every profile should evaluate with `just eval <profile>`. Before submitting changes, run `just fmt`, `just test`, and `just lint`. CI in `.gitea/workflows/ci.yaml` runs `just lint` and `just test`.

## Commit & Pull Request Guidelines

The current history uses concise imperative messages (`init`). Continue with short present-tense commits such as `add minimal microvm profile`.

Pull requests should describe the changed profile or module, list commands run, and call out host assumptions such as KVM support.
