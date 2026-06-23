# BUILDLOG

A working chronicle of building `mise` — a personal collection of composable Nix
flake devShells (*mise en place*: everything in its place before the work begins).
Complements `DECISIONLOG.md`: that file records *what* was decided and *why* for
structural choices; this file records the session-by-session process — debugging,
build verification, and the judgment calls made along the way.

**Format for every entry:**
- Strict chronological order, oldest at top, newest at bottom. Never insert
  mid-file — read the tail before appending.
- Each session header includes both date and time:
  `## Session N — YYYY-MM-DD HH:MM TZ` (use `date '+%Y-%m-%d %H:%M %Z'`).

---

## Session 1 — 2026-06-14 01:28 UTC

Built and debugged `languages/mercury/compilers/22.01.8.nix` — mise's first real
devShell, wrapping `pkgs.mercury` with deep-profiler, parallel, and debug grade
support. The same commit also added `flake.nix`/`flake.lock`, rewrote `README.md`
for the Flakes-based usage pattern, and added `DECISIONLOG.md`.

- Started from a draft `flake.nix` + `22.01.8.nix` with two bugs in `flake.nix`:
  `github.NixOS/...` (a `.` where a `:` belonged in the nixpkgs input URL), and
  `outputs` nested *inside* `inputs` rather than as a sibling attribute.
  Walkthrough-not-edit: Josiah diagnosed and fixed both himself; `nix flake check`
  / `nix flake show` then confirmed the flake's structure was sound.
- `nix develop .#mercury-22-01-8` entered a shell, but `which mmc` came back empty.
  Cause: `22.01.8.nix` had `buildImports`, which `mkShell` doesn't recognize, so
  `pkgs.mercury` never reached `PATH`. Two real fixes existed — `buildInputs` (the
  traditional `mkDerivation` attribute) or `packages` (the newer,
  `mkShell`-specific one). **Josiah chose `packages`** deliberately: it's "made
  specifically for devShells," following the convention the language maintainers
  are steering toward, even though both work identically here.
- With `mmc` reachable, the `overrideAttrs`/`preConfigure` block (deep profiler +
  `--with-default-grade=asm_fast.gc.par.stseg` + `--enable-libgrades=...debug`)
  kicked off a from-source build of `pkgs.mercury`. Josiah asked whether these
  grade flags would make *compiling Mercury itself* multi-threaded. Resolved: no —
  `.par` is about runtime parallelism for programs *compiled in* that grade, not
  the compiler's own build; build-time parallelism comes from nixpkgs'
  `enableParallelBuilding`, confirmed by watching CPU usage hit ~99% across all 16
  hyperthreads during the build.
- Once `mmc --version` resolved cleanly, did a full line-by-line walkthrough of
  both files: lambdas as Nix's only function form (`pkgs: {...}` and the nested
  `old: {...}` passed to `.overrideAttrs`); `old` as the *entire* original
  `mkDerivation` recipe (`pname`, `src`, `configureFlags`, phases, etc.) that
  `overrideAttrs` merges over, not just compiler flags; `$out` as this
  derivation's own `/nix/store/<hash>-...` path; and decoding the grade string
  `asm_fast.gc.par.stseg` as backend (`asm_fast`) + GC strategy (`.gc`) +
  parallelism model (`.par`) + stack allocation (`.stseg`), plus what
  `--enable-deep-profiler` and `--enable-libgrades` each add.

**Outcome:** `mercury-22-01-8` devShell works — `nix develop .#mercury-22-01-8`
drops into a shell with `mmc` on `PATH`, built with the grade configuration Josiah's
own comment in the file describes: "more robust grade configurations for better
profiling, parallelization, and debugging capabilities."

**Next:** this same session went on to give `pineapple-paint-nightmare-95` its own
`flake.nix` that consumes this devShell directly as a flake input — mise's first
real consumer (see that project's BUILDLOG, Session 2, for the consumer side).

---

## Session 2 — 2026-06-23 18:16 UTC

Expanded mise from a Mercury-only environment into version-pinned, composable tool
environments for Cinnabar and Cinnabar-worked.

- Josiah directed the required Mercury-grade set and evaluated the implications of
each grade. The resulting library grades are `asm_fast.par.gc.stseg`,
`asm_fast.gc.stseg` (the new default), `asm_fast.gc.debug.stseg`,
`asm_fast.gc.prof.stseg`, `asm_fast.gc.profdeep.stseg`, and `asm_fast.gc.tr`.
- Josiah identified that Bats source pinning at the flake root would become brittle
when supporting multiple Bats versions. After weighing flake-input pinning against
version-local fixed source pins, **Josiah chose version-local pins**. Bats 1.12.0
and Mercury 22.01.8 now each fetch their pinned nixpkgs source directly with a
fixed revision and `narHash` in their version expressions.
- Added Bats 1.12.0 and refactored mise to export both standalone devShells and
composable package lists. The consumer shells compose package lists directly:
`inputsFrom` was evaluated and rejected because it did not put child `mkShell`
packages on the parent shell PATH.
- Josiah performed the decisive environment evaluations: entered the real Cinnabar
devShell, checked `which` and `type -a`, ran `mmc --version` and `bats --version`,
and updated consumer lock files with `nix flake update mise`.
- All six enabled Mercury grades were validated by compiling and linking Cinnabars
stdlib-using `tokenizer.m` in isolated temporary directories. Every grade passed;
the only output was an existing determinism warning in the exercise source.
- The zsh issue was isolated from Nix package composition through comparative Bash
and zsh tests. Josiah restored his known-good global zsh configuration; Cinnabar
now uses a project-local `ZDOTDIR` wrapper that restores the dev-shell PATH after
the users normal zsh startup files run. Both `mmc` and `bats` resolve from
`/nix/store` in `nix develop -c zsh`.

**Outcome:** Cinnabars composed shell exposes Mercury 22.01.8 and Bats 1.12.0
from its Nix closure, while normal user zsh configuration remains independent.

**Next:** add future tool or compiler versions as separate version expressions with
their own fixed source revisions and hashes; update consumer locks after each mise
release.
