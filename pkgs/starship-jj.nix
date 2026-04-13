# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitLab,
  lib,
  nix-update-script,
  rustPackages,
  versionCheckHook,
}:
let
  pname = "starship-jj";
  version = "0.7.0";
in
rustPackages.rustPlatform.buildRustPackage (final: {
  inherit pname version;

  src = fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    tag = version;

    hash = "sha256-EgOKjPJK6NdHghMclbn4daywJ8oODiXkS48Nrn5cRZo=";
  };

  cargoHash = "sha256-NNeovW27YSK/fO2DjAsJqBvebd43usCw7ni47cgTth8=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script {
    attrPath = "starship-jj";
    extraArgs = [ "-F" ];
  };

  meta = {
    homepage = "https://gitlab.com/lanastara_foss/starship-jj";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
})
