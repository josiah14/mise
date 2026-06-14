# Decision Log

## 2026-06-01 — Use Nix Flakes instead of classic nix-shell

**Decision:** All mise environments are defined as named `devShells` in a `flake.nix`, entered
with `nix develop`. Classic `nix-shell` + `shell.nix` is not used.

**Rationale:** Classic nix-shell pulls nixpkgs from whatever channel is installed on the machine,
making environments non-reproducible across machines and over time. Flakes lock nixpkgs to a
specific commit in `flake.lock`, guaranteeing identical tool versions everywhere. Nixpkgs itself
uses Flakes, which means breaking the feature would be self-inflicted — a strong signal that the
long-standing "experimental" label reflects an unresolved governance debate, not actual
instability.

**Consequence:** Consuming projects reference mise as a flake input and compose environments via
`inputsFrom` in their own `flake.nix`. The `mkShell + inputsFrom` composition pattern is
unchanged; only the outer structure moves from standalone `.nix` files to Flakes outputs.

## 2026-06-01 — Single root flake with many fine-grained devShells

**Decision:** One `flake.nix` at the repo root exports many named `devShells`, each a minimal
composable unit. Subdirectories under `languages/` and `tools/` hold leaf `.nix` files that the
root flake imports — those leaves are not flakes themselves, just plain Nix expressions.

**Rationale:** A flake-per-unit layout (each subdirectory its own flake) would force consumers
to maintain a separate flake input per directory and would multiply lockfiles. One root flake
means one input for consumers, one lockfile, and clean piecewise composition via `inputsFrom`.

**Consequence:** Adding a new unit means dropping a `.nix` file into the right subdirectory and
wiring it into `flake.nix`'s `devShells.${system}` attribute set.

## 2026-06-01 — Scope: system-level dependencies only

**Decision:** Mise pins language runtimes, package-manager binaries, and system CLIs. It does
not pin language-level libraries (Black, ESLint, mypy, etc.) — those belong in language-native
package managers (`pyproject.toml`, `package.json`, etc.).

**Rationale:** Nix excels at pinning system binaries but is awkward at pinning language packages
across multiple runtime versions — cross-products of (language version × tool × tool version)
explode, and coupling that should compose independently. Language package managers handle this
naturally. Putting both in mise creates two sources of truth for the same dependency.

**Consequence:** Mise stays focused on a tractable surface area. Projects layer their own
language lockfiles on top of mise's runtimes and tooling executables.

## 2026-06-01 — Source layout

**Decision:** Files are organized under:

```
languages/<language>/{interpreters,compilers,runtimes}/<version>.nix
languages/<language>/package-managers/<name>.nix
tools/<tool>.nix
```

**Rationale:** Self-documenting hierarchy — anyone browsing the repo can see what's a runtime
versus what's a package manager versus what's a standalone CLI. The flat alternative (every
unit at the same level) gets hard to navigate as mise grows.

**Consequence:** Adding Python 3.15 means dropping `languages/python/interpreters/3.15.nix`.
Adding a new tool means dropping `tools/<name>.nix`. Filenames can use any version format
(`3.14.nix`, `22.01.8.nix`), but Nix attribute names can't start with a digit — the exported
shell name uses a prefix and dashes: file `3.14.nix` exports shell `python-3-14`.

## 2026-06-01 — Track `nixpkgs-unstable`, update as needed

**Decision:** The flake's nixpkgs input tracks `nixpkgs-unstable`. `nix flake update` is run on
an "as-needed" cadence at this stage of the project — when a tool's age starts causing problems
or when a project needs something newer than the current lock provides.

**Rationale:** `nixpkgs-unstable` gets new tool versions fastest. The lockfile pins to a
specific commit at update time, preserving reproducibility between updates. "As needed" avoids
busywork at this stage — mise is a personal project with no SLAs.

**Consequence:** Anyone using mise gets whatever versions were current at the last
`nix flake update`. Revisit cadence if the project grows or stalls long enough that updates
become disruptive when they happen.

## 2026-06-01 — Two layers of pinning

**Decision:** Mise's reproducibility scope ends at the tool layer. Language-level libraries are
pinned by the project's own package-manager lockfile (`poetry.lock`, `package-lock.json`,
`environment.yml`, etc.).

**Rationale:** Network-dependent operations (Poetry pulling from PyPI, conda from conda-forge)
operate on remotes nix doesn't control. The tool *binary* is reproducible from `flake.lock`;
the *libraries* the tool fetches are reproducible from their own lockfile. Trying to make nix
track both creates a coupling problem with no clean solution.

**Consequence:** Documented in README. Consumers know to commit both `flake.lock` (for the tool
layer) and their language lockfile (for the library layer). Remote protocol drift over long
intervals can still break old locks — periodic `nix flake update` keeps the tool layer current.

## 2026-06-01 — Consumer-side `follows` pattern for shared nixpkgs

**Decision:** Consuming projects should pin mise's nixpkgs to their own:

```nix
inputs.mise.inputs.nixpkgs.follows = "nixpkgs";
```

**Rationale:** Without `follows`, the build closure contains both mise's nixpkgs and the
consumer's — two potentially different versions of every shared package. `follows` collapses
them so the entire composition resolves against one nixpkgs.

**Consequence:** Documented as the recommended consumer pattern in README. Consumers can omit
`follows` if they intentionally want a divergent nixpkgs version.

## 2026-06-01 — Defer composition conflict resolution

**Decision:** At this stage, assume clean composition. Don't pre-design mechanisms for handling
conflicts (e.g., `python-3-13` + `python-3-14` both on `$PATH`; `poetry` + `conda` both
managing Python environments).

**Rationale:** Solving for hypothetical conflicts adds complexity before there's evidence
they'll arise in real use. Premature design.

**Consequence:** If a real conflict appears in a real consuming project, address it then —
either by documenting which units cohabit cleanly or by adding detection/prevention. Until
then, mise trusts the consumer to compose sensibly.
