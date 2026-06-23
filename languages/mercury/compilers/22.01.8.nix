pkgs: {
  mercury-22-01-8 = pkgs.mkShell {
    packages = [
      (pkgs.mercury.overrideAttrs (old: {
        # Correct canonical grade names for Mercury 22.01.8.
        # asm_fast.par.gc.stseg      — default: fast, parallel, Boehm GC, segmented stack
        # asm_fast.gc.stseg          — standard sequential native build
        # asm_fast.gc.debug.stseg    — for mdb debugging
        # asm_fast.gc.prof.stseg     — flat profiling
        # asm_fast.gc.profdeep.stseg — deep profiling
        # asm_fast.gc.tr             — trailing for solver types / CLP
        preConfigure = ''
          mkdir -p $out/lib/mercury/cgi-bin
          configureFlags="--enable-deep-profiler=$out/lib/mercury/cgi-bin --with-default-grade=asm_fast.gc.stseg --enable-libgrades=asm_fast.par.gc.stseg,asm_fast.gc.stseg,asm_fast.gc.debug.stseg,asm_fast.gc.prof.stseg,asm_fast.gc.profdeep.stseg,asm_fast.gc.tr"
        '';
      }))
      # readline and ncurses required by mdb (the Mercury debugger) at link time.
      pkgs.readline
      pkgs.ncurses
    ];
  };
}
