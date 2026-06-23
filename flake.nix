{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    bats-nixpkgs.url = "github:NixOS/nixpkgs/5a722a7155bfc9fbe657f28d26b71860d95324bc";
  };

  outputs = { self, nixpkgs, bats-nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      batsPkgs = bats-nixpkgs.legacyPackages.${system};
      mercuryPackages = import ./languages/mercury/compilers/22.01.8.nix pkgs;
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
