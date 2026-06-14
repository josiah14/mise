# mise

*mise en place* — everything in its place before the work begins.

The term comes from classical French culinary practice: before service, a
professional kitchen prepares every ingredient, tool, and station in advance.
Auguste Escoffier's brigade system made it a professional discipline — a cook's
mise was a mark of character. The principle generalizes: before the real work
starts, make the environment ready.

This is a collection of composeable [Nix Flakes](https://nixos.wiki/wiki/Flakes) dev shells.
Each named shell defines a minimal unit — a language runtime, a package manager binary, or a
system CLI — that can be used standalone or composed piecewise with others using
`mkShell` + `inputsFrom`.

## Scope

Mise pins **system-level dependencies**:

- Language runtimes (Python, Node, Mercury, …)
- Package-manager binaries (Poetry, Conda, npm, …)
- System CLIs (jq, ripgrep, protoc, …)

Mise does **not** pin language-level libraries (Black, ESLint, mypy, etc.). Those belong in the
language's native package manager — `pyproject.toml` for Python, `package.json` for JavaScript,
and so on. Mise provides the runtime and tooling; the project layers its own library
dependencies on top.

## Usage

Requires Nix with Flakes enabled (`experimental-features = nix-command flakes` in `nix.conf`).

### Drop into a single environment

```sh
nix develop github:josiah14/mise#mercury-22-01-8
```

The fragment after `#` names the devShell — see [Environments](#environments) for what's
currently available.

### Compose multiple environments in a project

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mise.url    = "github:josiah14/mise";
    mise.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, mise, ... }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [
          mise.devShells.${system}.python-3-14
          mise.devShells.${system}.poetry
          mise.devShells.${system}.jq
        ];
      };
    };
}
```

The `mise.inputs.nixpkgs.follows = "nixpkgs"` line collapses mise's nixpkgs into the project's
own — without it, the build closure contains two nixpkgs versions.

## Repository layout

```
mise/
  flake.nix                              ← root flake, exports every devShell
  languages/
    <language>/
      interpreters/                      ← or compilers/ or runtimes/
        <version>.nix
      package-managers/
        <name>.nix
  tools/
    <tool>.nix
```

Each leaf `.nix` file is a function `pkgs: { <shell-name> = pkgs.mkShell { ... }; }`. The root
`flake.nix` imports all leaves and merges them into `devShells.${system}`.

**Naming:** filenames can use any version format (`3.14.nix`, `22.01.8.nix`), but Nix attribute
names can't start with a digit. The exported shell name uses a prefix and dashes — file
`languages/python/interpreters/3.14.nix` exports shell `python-3-14`.

## Two layers of pinning

When mise is used in a project, two lockfiles govern what you get:

1. **`mise/flake.lock`** pins the nixpkgs commit mise uses, which pins the version of every
   tool mise provides (the Python interpreter, the Poetry binary, etc.).
2. **The project's language lockfile** (`poetry.lock`, `package-lock.json`, `environment.yml`,
   etc.) pins the libraries the tool fetches at install time.

Mise's reproducibility stops at the tool layer. Network-dependent operations (Poetry pulling
from PyPI, conda from conda-forge) can drift over time independently of mise's lock — periodic
updates keep things current.

## Updating

```sh
nix flake update
```

advances `flake.lock` to the latest `nixpkgs-unstable`, refreshing all tool versions in one go.
Cadence is **as-needed** at this stage — run it when a tool's age starts causing problems
(remote protocol drift, missing features in the locked version) or when a new project needs
something the current lock doesn't have.

## Environments

| Shell | Provides |
|-------|----------|
| *(none yet — work in progress)* | |

## Design decisions

See [`DECISIONLOG.md`](DECISIONLOG.md) for the reasoning behind structural choices.

## License

[MIT](LICENSE).
