# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  installShellFiles,
  kubectl,
  runCommand,
}:
let
  pname = "kubectl-completions";
  inherit (kubectl) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";
    nativeBuildInputs = [ installShellFiles ];
    buildInputs = [ kubectl ];
  }
  ''
    installShellCompletion \
      --cmd kubectl \
      --bash <(kubectl completion bash) \
      --fish <(kubectl completion fish) \
      --zsh <(kubectl completion zsh)
  ''
