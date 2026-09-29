# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  bubblewrap,
  fetchFromGitHub,
  lib,
  makeBinaryWrapper,
  nix-update-script,
  rustPlatform,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (final: {
  pname = "ai-jail";
  version = "2.2.1";

  src = fetchFromGitHub {
    owner = "akitaonrails";
    repo = final.pname;
    tag = "v${final.version}";
    hash = "sha256-1Jxl05CJHWjciPwicYlCMXtsOSTLkNWnCod4KOjr6Wk=";
  };

  cargoHash = "sha256-LTK4lR+jgRwbA/8H2wQRIJUdlLWPN+EnRClP2RzRdqY=";

  nativeBuildInputs = [
    bubblewrap
    makeBinaryWrapper
  ];

  BWRAP_BIN = lib.getExe bubblewrap;
  RUSTFLAGS = "--remap-path-prefix=$(builtins.storeDir}=/build";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  postFixup = ''
    wrapProgram "$out/bin/ai-jail" \
      --set BWRAP_BIN "${final.BWRAP_BIN}"
  '';

  passthru.updateScript = nix-update-script {
    attrPath = final.pname;
    extraArgs = [ "-F" ];
  };

  meta = {
    description = "Sandbox wrapper for AI coding agents";
    homepage = "https://github.com/akitaonrails/ai-jail";
    license = lib.licenses.gpl3Only;
    mainProgram = final.pname;
  };
})
