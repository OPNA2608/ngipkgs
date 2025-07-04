{
  runCommand,
  pinmux,
  libresoc-nmigen,
}:
runCommand "libresoc.v"
  {
    version = "unstable-2024-03-31";

    nativeBuildInputs = [
      libresoc-nmigen
      pinmux
    ];

    # FIX: https://github.com/NixOS/nixpkgs/issues/389149
    meta.broken = true;
  }
  ''
    mkdir pinmux
    ln -s ${pinmux} pinmux/ls180
    export PINMUX="$(realpath ./pinmux)"
    python3 -m soc.simple.issuer_verilog \
      --debug=jtag --enable-core --enable-pll \
      --enable-xics --enable-sram4x4kblock --disable-svp64 \
      $out
  ''
