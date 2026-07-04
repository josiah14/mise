{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      packagesFor = system: {
        mercury-22-01-8 = import ./languages/mercury/compilers/22.01.8.nix { inherit system; };
        bats-1-12-0 = import ./tools/bats/1.12.0.nix { inherit system; };
      };
    in
    {
      lib = forAllSystems packagesFor;

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = packagesFor system;
        in
        {
          mercury-22-01-8 = pkgs.mkShell {
            packages = packages.mercury-22-01-8;

            shellHook = nixpkgs.lib.optionalString (system == "aarch64-linux") ''
              # asm_fast.*.stseg's nondet stack segment auto-growth doesn't
              # reliably kick in on aarch64-linux, so even non-recursive
              # programs can overflow the 64k-word default. Force a larger
              # initial allocation to work around it.
              export MERCURY_OPTIONS="--nondetstack-size 16384"
            '';
          };
          bats-1-12-0 = pkgs.mkShell {
            packages = packages.bats-1-12-0;
          };
        });
    };
}
