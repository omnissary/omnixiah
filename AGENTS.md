# Repository Guidelines

## Project Structure & Module Organization

Omnixiah is a NixOS spin built around reusable NixOS profiles.

- `flake.nix`: inputs, the overlaid `pkgs` package set, apps, checks, formatter, `profiles`, and `modules`.
- `modules/`: shared modules. `modules/default.nix` registers every file next to it, so adding `modules/tc.nix` is enough.
- `overlays/packages/<name>/`: package overlays, one directory per package, registered the same way.
- `profiles/`: profile modules, registered by name in `profiles/default.nix`.
  - `base`: distribution defaults, see the layers below.
  - `debug`, `qemu`: system profiles.
  - `microvm`: instantiated for every supported Linux system and exposed as the runnable `microvm` package and app.
  - `rockchip`: SoC family boot and image setup in `profiles/rockchip/default.nix`, driven by `hardware.rockchip.uBoot`.
  - `orangepi-3b`: board profile. A board is `profiles/rockchip/<board>.nix`, imports `./.`, selects its U-Boot (nixpkgs `pkgs.uboot*` when available, otherwise `pkgs.uboot-rockchip`), and is added to `boards` in `tests/modules/rockchip.nix`.
  - `allwinner`: SoC family boot and image setup in `profiles/allwinner/default.nix`, driven by `hardware.allwinner.uBoot`, with `pkgs.linuxPackages_allwinner` as the kernel. The image carries U-Boot at 8 KiB for SD boot; `system.build.felBoot` uploads the same U-Boot over USB for boards without SD, which then boots extlinux from USB storage.
  - `chip`: board profile for the NextThing C.H.I.P. (armv7l): U-Boot, device tree, RTL8723BS Wi-Fi and Bluetooth, power key, USB root. The root lives on USB storage until NAND boot lands.
  - `pocketchip`: board profile for the PocketC.H.I.P. It imports `chip` and adds the display, keyboard and touch overlay, the Fn keyboard layers for X and the console, touchscreen calibration, backlight access, and battery handling.
  - Allwinner boards are directories under `profiles/allwinner/<board>/` that import their parent board or `../.`, keep device tree overlays and other board data next to `default.nix`, take U-Boot from `pkgs.uboot-allwinner`, and are added to `boards` in `tests/modules/allwinner.nix`. armv7l has no binary cache, so consumers build these systems cross by setting `nixpkgs.buildPlatform` and `nixpkgs.hostPlatform`.

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

Offline evaluation must work on installed systems. Flake input sources are part of the system configuration and must survive garbage collection. Omnixiah's base profile retains its own input graph. Consumers pass `rootFlake = self` to `lib.nixosSystem`, which retains their complete input graph and exposes it at `/etc/omnixiah/system`.

Omnixiah owns the installed system's legacy Nix paths. Keep `NIX_PATH` entries under `/etc/omnixiah` so their values stay stable across rebuilds. Consumers export overlays from their flakes and register them through `omnixiah.nix.overlays`, then add source aliases through `omnixiah.nix.sources`. The profile applies the same ordered overlays to the system package set and generates the legacy overlay file. Do not set a second `nixpkgs-overlays` entry or another `/etc` source tree in consumers.

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

Stage changes by explicit path (`git add <path>...`, `git rm <path>...`). Never use `git add -A`, `git add .`, or `git commit -a`: the working tree holds untracked local notes that must not be committed. Check `git diff --cached --stat` before every commit.

Pull requests should describe the changed profile or module, list commands run, and call out host assumptions such as KVM support.
