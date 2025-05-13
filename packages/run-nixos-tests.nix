# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  flakePackages,
  lib,
  linkFarm,
  writers,

  nix-output-monitor,
}:
let
  nixos-tests = lib.trivial.pipe flakePackages.self.checks [
    (lib.attrsets.filterAttrs (_: v: lib.strings.hasPrefix "nixos-test-driver-" v.name))
    (lib.mapAttrsToList (name: path: { inherit name path; }))
    (linkFarm "nixos-tests")
  ];
in
writers.writeExeclineBin { flags = "-WS0"; } "run-nixos-tests" ''
  multisubstitute {
    importas -D /tmp TMPDIR TMPDIR
    importas -i PATH PATH
  }
  export PATH ''${PATH}:${lib.strings.makeBinPath [ nix-output-monitor ]}

  backtick -E result { nom build --print-out-paths .#run-nixos-tests.passthru.nixos-tests }
  elglob -v dirs ''${result}/*
  forx -E -o 0 -p dir { $dirs }
    if { eltest -x ''${dir}/bin/nixos-test-driver }
    backtick -E test { basename $dir }
    if { mkdir -p ''${TMPDIR}/nixos-test-''${test} }
    systemd-run 
      --unit=nixos-test@$test 
      --property=CPUWeight=1
      --slice=background-nixos_test
      --service-type=oneshot 
      --setenv=TMPDIR=''${TMPDIR}/nixos-test-''${test}
      --wait 
      --user 
      ''${dir}/bin/nixos-test-driver
''
// {
  passthru = { inherit nixos-tests; };
}
