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
  version = "0.6.0";
in
rustPackages.rustPlatform.buildRustPackage (final: {
  inherit pname version;

  src = fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    tag = version;

    hash = "sha256-HTkDZQJnlbv2LlBybpBTNh1Y3/M8RNeQuiked3JaLgI=";
  };

  cargoHash = "sha256-E5z3AZhD3kiP6ojthcPne0f29SbY0eV4EYTFewA+jNc=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://gitlab.com/lanastara_foss/starship-jj";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
})
