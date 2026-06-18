pkgs: {
  mercury-22-01-8 = pkgs.mkShell {
    packages = [
      (pkgs.mercury.overrideAttrs (old: {
        # Correct canonical grade names for Mercury 22.01.8.
        # asm_fast.par.gc.stseg  — default: fast, parallel, Boehm GC, segmented stack
        # asm_fast.gc.debug.stseg — for mdb debugging
        preConfigure = ''
          mkdir -p $out/lib/mercury/cgi-bin
          configureFlags="--enable-deep-profiler=$out/lib/mercury/cgi-bin --with-default-grade=asm_fast.par.gc.stseg --enable-libgrades=asm_fast.par.gc.stseg,asm_fast.gc.debug.stseg"
        '';
      }))
      # readline and ncurses required by mdb (the Mercury debugger) at link time.
      pkgs.readline
      pkgs.ncurses
    ];
  };
}
