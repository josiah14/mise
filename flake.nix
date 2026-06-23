{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mercury-22-01-8-nixpkgs.url = "github:NixOS/nixpkgs/5a722a7155bfc9fbe657f28d26b71860d95324bc";
    bats-1-12-0-nixpkgs.url = "github:NixOS/nixpkgs/5a722a7155bfc9fbe657f28d26b71860d95324bc";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
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
