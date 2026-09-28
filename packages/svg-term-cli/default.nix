# SPDX-FileCopyrightText: 2024-2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: MIT

{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  nix-update-script,
  nodejs,
  stdenv,
  yarnBuildHook,
  yarnConfigHook,
  yarnInstallHook,
}:
stdenv.mkDerivation (final: {
  pname = "svg-term-cli";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "marionebl";
    repo = final.pname;
    rev = "v${final.version}";

    hash = "sha256-sB4/SM48UmqaYKj6kzfjzITroL0l/QL4Gg5GSrQ+pdk=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = final.src + "/yarn.lock";
    hash = "sha256-4Q1NP3VhnACcrZ1XUFPtgSlk1Eh8Kp02rOgijoRJFcI=";
  };

  nativeBuildInputs = [
    nodejs
    yarnBuildHook
    yarnConfigHook
    yarnInstallHook
  ];

  meta.license = lib.licenses.mit;
  meta.mainProgram = "svg-term";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--override-filename=${builtins.toString ./default.nix}" ];
  };
})
