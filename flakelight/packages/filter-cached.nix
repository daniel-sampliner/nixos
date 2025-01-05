# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  writers,
}:
writers.writeExecline { flags = "-WS1"; } "/bin/filter-cached" ''
  forstdin -E -p attr
  if -Xnt { redirfd -w 1 /dev/null nix path-info --eval-store auto --store $1 $attr }
  if -Xnt { redirfd -w 1 /dev/null nix path-info --eval-store auto --store https://cache.nixos.org $attr }
  echo $attr
''
