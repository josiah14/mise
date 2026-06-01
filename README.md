# mise

*mise en place* — everything in its place before the work begins.

The term comes from classical French culinary practice: before service, a
professional kitchen prepares every ingredient, tool, and station in advance.
Auguste Escoffier's brigade system made it a professional discipline — a cook's
mise was a mark of character. The principle generalizes: before the real work
starts, make the environment ready.

This is a collection of composeable nix-shell environments. Each file defines a
logical grouping of tools that can be used standalone or combined with others
using `mkShell` + `inputsFrom`.

## Usage

Drop into a single environment:

```sh
nix-shell /path/to/mise/mercury.nix
```

Compose multiple environments in a project `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  inputsFrom = [
    (import /path/to/mise/mercury.nix { inherit pkgs; })
    (import /path/to/mise/clingo.nix  { inherit pkgs; })
  ];
}
```

## Environments

| File | Provides |
|------|----------|
| `mercury.nix` | Mercury compiler (`mmc`) |
