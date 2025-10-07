# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitLab,
  lib,
  nix-update-script,
  rustPackages_1_88,
  versionCheckHook,
}:
let
  pname = "starship-jj";
  version = "0.6.0";
in
rustPackages_1_88.rustPlatform.buildRustPackage (final: {
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
