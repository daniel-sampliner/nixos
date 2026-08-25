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
  version = "1.20.1";

  src = fetchFromGitHub {
    owner = "akitaonrails";
    repo = final.pname;
    tag = "v${final.version}";
    hash = "sha256-veF08HRDB2mCrVGfaXZ1jflH9tJQp7agr9e3Y8VrgZ8=";
  };

  cargoHash = "sha256-6gi0Xn+yOT2Xw07FOaEq89zgyx/JBXAwgPiLw4QVfRs=";

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
