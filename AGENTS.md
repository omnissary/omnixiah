# Repository Guidelines

## Project Structure & Module Organization

Omnixiah is a NixOS spin built around MicroVM profiles. The root `flake.nix` defines inputs, packages, apps, checks, formatter, `nixosModules`, and `lib.profiles` metadata. `lib/microvm.nix` exports MicroVM helpers, including `mkMicrovmProfile`. `modules/` holds shared NixOS modules such as `modules/firewall.nix`. `profiles/default.nix` is the profile registry; `profiles/vm.nix` contains VM-only login defaults; runnable profiles live in files such as `profiles/minimal.nix`.

Use neighboring repositories as local context: `../infra/flake.nix` is the source for the canonical corpix `nixpkgs` input, `../microvm` is the MicroVM implementation, and `../nixpkgs` is useful for source inspection.

## Build, Test, and Development Commands

Use the lowercase `justfile` as the command surface.

- `just profiles`: list profiles from `.#lib.profiles`.
- `just eval minimal`: evaluate the minimal profile hostname.
- `just build minimal`: build the MicroVM runner.
- `just run minimal`: run the MicroVM profile.
- `just lint`: run `nix flake check --show-trace`.
- `just test`: run all module VM tests from `.#lib.tests`.
- `just fmt`: run treefmt through `nix fmt`.

Direct Nix commands are acceptable for debugging, for example `nix build .#packages.x86_64-linux.minimal`.

## Coding Style & Naming Conventions

Use two-space indentation for Nix files. Use lower camel case for Nix option-style names and kebab-case for files or directories. Add profiles by registering them in `profiles/default.nix` and placing implementation in `profiles/<name>.nix`.

Prefer `inherit (lib) mkDefault optionalAttrs ...;` in a local `let` over repeated `lib.<name>` calls. Do not add explanatory code comments; improve structure or Markdown documentation instead.

No shortcuts: follow the architecture, keep changes cohesive, and chase failures to their cause. Keep insecure or local-only VM behavior out of shared modules; root autologin and no-password login belong in `profiles/vm.nix`, not `modules/base.nix`.

## Testing Guidelines

Tests under `tests/modules/` should exercise module evaluation or VM behavior for changed modules. Every profile should evaluate with `just eval <profile>`. Before submitting changes, run `just fmt`, `just test`, and `just lint`. Treefmt is wired with nixfmt, deadnix, statix, and shellcheck.

## Commit & Pull Request Guidelines

The current history uses concise imperative messages (`init`). Continue with short present-tense commits such as `add minimal microvm profile`.

Pull requests should describe the changed profile or module, list commands run, and call out host assumptions such as KVM support.
