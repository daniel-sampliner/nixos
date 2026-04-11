# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  callPackage,
  common-updater-scripts,
  fetchFromGitHub,
  inputs',
  installShellFiles,
  jq,
  lib,
  nixfmt,
  runCommand,
  stdenv,
  versionCheckHook,
  writeShellApplication,
  zig,
}:
stdenv.mkDerivation (final: {
  pname = "zmx";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "neurosnap";
    repo = final.pname;
    rev = "v${final.version}";
    hash = "sha256-ehbriI3xW40oVUbokhNuxYvueqFhkmHCVNZpqxQLr3A=";
  };
  deps = callPackage ./build.zig.zon.nix { };

  nativeBuildInputs = [
    installShellFiles
    zig.hook
  ];

  preBuild = ''
    cp --dereference --recursive "${final.deps}" "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  postInstall = lib.strings.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd zmx \
      --bash <($out/bin/zmx completions bash) \
      --fish <($out/bin/zmx completions fish) \
      --zsh <($out/bin/zmx completions zsh)
  '';

  doCheck = true;
  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";

  meta = {
    description = "Session persistence for terminal processes";
    homepage = "https://zmx.sh/";
    license = lib.licenses.mit;
    mainProgram = final.pname;
  };

  passthru =
    let
      zig2nix = runCommand "zig2nix" { } ''
        install -D "${inputs'.zig2nix.apps.zig2nix-latest.program}" "$out/bin/zig2nix"
      '';

      updater = writeShellApplication {
        name = "${final.pname}-updater";
        runtimeInputs = [
          common-updater-scripts
          jq
          nixfmt
          zig2nix
        ];
        text = builtins.readFile ./update.sh;
      };
    in
    {
      inherit updater;
      updateScript = [
        (lib.getExe updater)
        final.src.gitRepoUrl
      ];
    };
})
