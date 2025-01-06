# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  fetchFromGitHub,
  inputs',
  lib,
  makeBinaryWrapper,
  nix-update-script,

  jre_headless,
}:
let
  pname = "asciinema-vsync";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "JakeWharton";
    repo = pname;
    rev = "290343c0b0c425671f8db3556d054baae3818da0";

    hash = "sha256-LiZGqnDn4Eh9oGp/X8REUYWIQrWZcBpgsskBn6mT+3c=";
  };
in
inputs'.gradle2nix.builders.buildGradlePackage {
  inherit pname src;

  version = "${version}-1";

  lockFile = ./gradle.lock;

  gradleBuildFlags = [ "assemble" ];
  nativeBuildInputs = [ makeBinaryWrapper ];

  installPhase = ''
    install -D build/asciinema-vsync.jar "$out/bin/${pname}"
    wrapProgram $out/bin/"${pname}" --suffix PATH : "${lib.makeBinPath [ jre_headless ]}"
  '';

  meta.license = lib.licenses.asl20;
  passthru.updateScript = nix-update-script { };
}
