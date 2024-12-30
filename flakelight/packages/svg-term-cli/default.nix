# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: MIT

{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  mkYarnPackage,
  nix-update-script,
}:
let
  pname = "svg-term-cli";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "marionebl";
    repo = pname;
    rev = "v${version}";

    hash = "sha256-sB4/SM48UmqaYKj6kzfjzITroL0l/QL4Gg5GSrQ+pdk=";
  };
in
mkYarnPackage {
  inherit pname src version;

  packageJSON = ./package.json;

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-4Q1NP3VhnACcrZ1XUFPtgSlk1Eh8Kp02rOgijoRJFcI=";
  };

  buildPhase = ''
    runHook preBuild

    export HOME=$PWD/yarn_home
    yarn --offline build

    runHook postBuild
  '';

  postInstall = ''
    bin="$(readlink -e $out/bin/svg-term)"
    chmod a+x "$bin"
  '';

  meta.license = lib.licenses.mit;
  meta.mainProgram = "svg-term";

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--override-filename=${builtins.toString ./default.nix}" ];
  };
}
