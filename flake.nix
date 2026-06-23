{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mercuryPackages = import ./languages/mercury/compilers/22.01.8.nix { inherit system; };
      batsPackages = import ./tools/bats/1.12.0.nix { inherit system; };
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
