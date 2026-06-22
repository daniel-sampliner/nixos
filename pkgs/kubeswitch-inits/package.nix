# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  installShellFiles,
  kubeswitch,
  redo-apenwarr,
  stdenvNoCC,

  COMMAND_NAME ? "kswitch",
}:
stdenvNoCC.mkDerivation {
  pname = "kubeswitch-inits";
  inherit (kubeswitch) version;
  inherit COMMAND_NAME;

  nativeBuildInputs = [
    installShellFiles
    redo-apenwarr
  ];
  buildInputs = [ kubeswitch ];

  src = ./.;

  buildPhase = ''
    runHook preBuild

    redo --jobs $NIX_BUILD_CORES

    runHook postBuild
  '';

  postInstall = ''
    installShellCompletion --zsh --name kswitch kswitch
    installShellCompletion --zsh _kswitch _switcher
    installShellCompletion completion.{bash,fish} init.{bash,fish}
  '';
}
