{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    }
    // import ./languages/mercury/inputs.nix
    // import ./tools/bats/inputs.nix;

  outputs = { self, nixpkgs, bats-1-12-0-nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mercuryPkgs = inputs."mercury-22-01-8-nixpkgs".legacyPackages.${system};
      batsPkgs = inputs."bats-1-12-0-nixpkgs".legacyPackages.${system};
      mercuryPackages = import ./languages/mercury/compilers/22.01.8.nix mercuryPkgs;
      batsPackages = import ./tools/bats/1.12.0.nix batsPkgs;
    in
    {
      lib.${system} = {
        mercury-22-01-8 = mercuryPackages;
        bats-1-12-0 = batsPackages;
      };

      devShells.${system} = {
        mercury-22-01-8 = pkgs.mkShell {
          packages = mercuryPackages;
        };
        bats-1-12-0 = pkgs.mkShell {
          packages = batsPackages;
        };
      };
    };
}
