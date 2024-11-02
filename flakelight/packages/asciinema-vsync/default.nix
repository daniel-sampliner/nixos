# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  fetchFromGitHub,
  fetchpatch,
  inputs',
  lib,
  makeBinaryWrapper,

  jre_headless,
}:
let
  pname = "asciinema-vsync";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "JakeWharton";
    repo = pname;
    rev = version;

    hash = "sha256-PaBI9fvy1zVYosdPtC6uQ9pTioqhi+OLpI3hnuhTbXI=";
  };
in
inputs'.gradle2nix.builders.buildGradlePackage {
  inherit pname src;

  version = "${version}-1";

  patches = [
    (fetchpatch {
      url = "https://github.com/JakeWharton/asciinema-vsync/pull/2.patch";
      hash = "sha256-2xJy8QhbawX+Bv+rdLpfex6Rf66QYk3BMh5YN1JoYls=";
    })
  ];

  lockFile = ./gradle.lock;

  gradleBuildFlags = [ "assemble" ];
  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    install -D build/asciinema-vsync.jar "$out/bin/${pname}"
    wrapProgram $out/bin/"${pname}" --suffix PATH : "${lib.makeBinPath [ jre_headless ]}"
  '';

  meta.license = lib.licenses.asl20;
}
