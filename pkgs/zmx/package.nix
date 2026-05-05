# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  installShellFiles,
  lib,
  nix-update-script,
  stdenv,
  versionCheckHook,
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

  zigDeps = zig.fetchDeps {
    inherit (final) src pname version;
    fetchAll = true;
    hash = "sha256-4jwdYJWSO39ZaO24ViG+rm3czP9mRB3Uj/RZArebP0Q=";
  };

  nativeBuildInputs = [
    installShellFiles
    zig.hook
  ];

  postConfigure = ''
    cp --dereference --recursive "${final.zigDeps}" "$ZIG_GLOBAL_CACHE_DIR/p"
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

  passthru = {
    inherit (final) zigDeps;
    updateScript = nix-update-script { extraArgs = [ "-F" ]; };
  };
})
