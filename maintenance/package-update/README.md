# Package updates

Omnixiah packages use the Nixpkgs `passthru.updateScript` protocol. The explicit registry in `packages.nix` limits discovery to packages maintained by this repository instead of traversing the inherited Nixpkgs package set.

Each update runs in an isolated Git worktree. A successful update is formatted, built, committed once, and fast-forwarded into the current branch. A failed worktree remains available for `update-continue` or can be discarded with `update-abort`.

Use `just update-list`, `just update <name>`, or `just update-all`. Package updates never push commits.
