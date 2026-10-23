# Fork synchronization

The fork synchronizer rebases maintained `omnixiah` branches onto their configured upstream branches. It creates an annotated recovery tag before rewriting history, runs repository-specific maintenance and validation commands, and stops for review before pushing.

The root `justfile` provides the command surface:

```console
just sync-status
just sync nixpkgs
just sync nixpkgs --update
just sync-continue nixpkgs
just sync-abort nixpkgs
just sync-push nixpkgs
```

`sync` requires a clean repository whose local branch exactly matches its Tatikoma branch. `sync-push` fetches Tatikoma again and uses an explicit `--force-with-lease`; it refuses to push if the remote branch changed after preparation.

Recovery tags use this form:

```text
archive/omnixiah/2026-10-23-8070f3754ac8
```

The registry is defined in `forks.nix` and validated by `config.nix`. Repository directories are resolved beneath the parent of the Omnixiah Git root, so sibling repositories are represented as `directory = "nixpkgs"` without path traversal. Update policies are:

- `requested`: run the update only when `--update` is supplied.
- `always`: run the update after every rebase.
- `never`: reject requested updates.

Managed update commits carry an `Omnixiah-Managed-Update` trailer. When another update is requested, previous managed update commits are removed from the rebased patch stack and regenerated on top of the new upstream state.

An interrupted rebase remains in the affected repository. Resolve its conflicts and run `just sync-continue <name>`, or restore the exact pre-sync commit with `just sync-abort <name>`.

Runtime state is stored below `${XDG_STATE_HOME}/omnixiah/fork-sync`, falling back to `${HOME}/.local/state/omnixiah/fork-sync`.
