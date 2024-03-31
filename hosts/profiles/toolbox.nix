# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages =
    let
      pp =
        builtins.attrValues {
          inherit (pkgs)
            bcc
            bpftrace
            findutils
            iproute2
            lsof
            ltrace
            procps
            psmisc
            strace
            sysstat
            trace-cmd
            util-linux
            ;
        }
        ++ [
          config.boot.kernelPackages.perf
          pkgs.dig.dnsutils
        ];
    in
    builtins.map (p: lib.setPrio ((p.meta.priority or 5) + 3) p) pp;

  programs.mtr.enable = true;
}
