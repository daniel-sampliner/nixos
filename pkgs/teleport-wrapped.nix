# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  makeBinaryWrapper,
  replaceDependency,
  replaceDependencies,
  runCommand,
  teleport,
  xdg-utils,

  browser ? null,
}:
let
  pkg = teleport;

  xdg-utils-wrapped =
    runCommand "${xdg-utils.name}.1.forcebrowser" { nativeBuildInputs = [ makeBinaryWrapper ]; }
      ''
        mkdir -p $out/bin
        makeWrapper "${lib.getExe' xdg-utils "xdg-open"}" "$out/bin/xdg-open" \
          --set XDG_CURRENT_DESKTOP X-Generic \
          --set-default BROWSER "${browser}" \
          --unset DISPLAY \
          --unset WAYLAND_DISPLAY
      '';
in
runCommand "${pkg.name}.1.wrapped" { nativeBuildInputs = [ makeBinaryWrapper ]; } ''
  mkdir "$out"
  ln -s "${pkg}"/* "$out"
  rm "$out/bin"
  mkdir "$out/bin"

  for b in "${pkg.client}/bin/"* "${pkg}/bin/"*; do
    dir=''${b%/*}
    bin=''${b##*/}
    if [[ -e $out/bin/$bin ]]; then
      continue
    fi

    if [[ -e $dir/.$bin-wrapped ]]; then
      b=$dir/.$bin-wrapped
    fi
    ln -s "$b" "$out/bin/$bin"

    wrapProgram "$out/bin/$bin" \
      ${lib.strings.optionalString (browser != null) ''--prefix PATH : "${xdg-utils-wrapped}/bin"''} \
      --set-default TELEPORT_TOOLS_VERSION off
  done
''
