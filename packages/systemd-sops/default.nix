{
  lib,
  stdenv,

  zig,
}:
stdenv.mkDerivation {
  pname = "systemd-sops";
  version = "0.0.1";

  src =
    let
      fs = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.difference ./. ./default.nix;
      };
    in
    fs;

  nativeBuildInputs = [ zig.hook ];
}
