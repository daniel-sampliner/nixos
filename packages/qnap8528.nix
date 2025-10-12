# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  kernelModuleMakeFlags ? linuxPackages.kernelModuleMakeFlags,
  lib,
  linuxPackages,
  nix-update-script,

  kernel ? linuxPackages.kernel,
  stdenv,
}:
let
  pname = "qnap8528";
  version = "1.14";

  src = fetchFromGitHub {
    owner = "0xGiddi";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-VJjN4HpQRpHt4ftG6L2CVHPfZMLvyQnjI2wpyws7Jus=";
  };

  kdir = "lib/modules/${kernel.modDirVersion}";
in
stdenv.mkDerivation {
  inherit pname src version;
  sourceRoot = "${src.name}/src";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" ];
  makeFlags = kernelModuleMakeFlags ++ [ "KERNEL_DIR=${kernel.dev}/${kdir}/build" ];

  installPhase = ''
    runHook preInstall

    install -Dm0444 -t "$out/${kdir}/misc" "${pname}.ko"

    runHook postInstall
  '';

  meta.license = lib.licenses.free;
  passthru.updateScript = nix-update-script { };
}
