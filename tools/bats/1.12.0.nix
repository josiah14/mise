{ system }:

let
  pkgs = import (builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "5a722a7155bfc9fbe657f28d26b71860d95324bc";
    narHash = "sha256-j9uBlHI0eJ9zWU9IlF6SlBBPdeJu30hcvar31IRKHpw=";
  }) { inherit system; };
in
[
  pkgs.bats
]
