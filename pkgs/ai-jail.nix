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
  version = "1.15.0";

  src = fetchFromGitHub {
    owner = "akitaonrails";
    repo = final.pname;
    tag = "v${final.version}";
    hash = "sha256-LPa0mdm28SYi68TD+b/QGD5YW2nu4RZosLMZv7Fvk+E=";
  };

  cargoHash = "sha256-Xrca9e9/utUJSliNvPFV53UdmnqBaNtP9aRINT2drnE=";

  buildInputs = [ bubblewrap ];
  nativeBuildInputs = [ makeBinaryWrapper ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  postFixup = ''
    wrapProgram "$out/bin/ai-jail" \
      --set BWRAP_BIN "${lib.getExe bubblewrap}"
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
