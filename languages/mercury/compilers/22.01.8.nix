pkgs: {
  mercury-22-01-8 = pkgs.mkShell {
    packages = [
      (pkgs.mercury.overrideAttrs (old: {
        # Choose some more robust grade configurations for better profiling,
        # parallelization, and debugging capabilities.
        preConfigure = ''
          mkdir -p $out/lib/mercury/cgi-bin
          configureFlags="--enable-deep-profiler=$out/lib/mercury/cgi-bin --with-default-grade=asm_fast.gc.par.stseg --enable-libgrades=asm_fast.gc.par.stseg.debug"
        '';
      }))
    ];
  };
}
