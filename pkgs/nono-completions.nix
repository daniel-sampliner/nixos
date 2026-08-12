# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  installShellFiles,
  nono,
  runCommand,
}:
let
  pname = "nono-completions";
  inherit (nono) version;
in
runCommand pname
  {
    inherit pname version;
    name = "${pname}-${version}";
    nativeBuildInputs = [ installShellFiles ];
    buildInputs = [ nono ];
  }
  ''
    export HOME=$PWD
    installShellCompletion \
      --cmd nono \
      --bash <(nono completion bash) \
      --fish <(nono completion fish) \
      --zsh <(nono completion zsh)
  ''
