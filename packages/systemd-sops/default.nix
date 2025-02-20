{
  lib,
  stdenv,

  zig,
}:
stdenv.mkDerivation {
  pname = "systemd-sops";
  version = "0.0.1";

  src = builtins.path { name = "systemd-sops"; path = ./.; };
    # let
    #   fs = lib.fileset.toSource {
    #     root = builtins.path { path = ./.; name = "systemd-sops"; };
    #     fileset = lib.fileset.difference ./. ./default.nix;
    #   };
    # in
    # fs;

  nativeBuildInputs = [ zig.hook ];
}
