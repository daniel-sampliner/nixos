# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  lib,
  writers,

  jq,
  nix-eval-jobs,
}:
writers.writeExecline { flags = "-WS1"; } "/bin/gen-gh-jobs" ''
  multisubstitute {
    importas -i GC_ROOTS_DIR GC_ROOTS_DIR
    importas -D 8192 MAX_MEMORY_SIZE MAX_MEMORY_SIZE
  }

  pipeline {
    "${lib.getExe nix-eval-jobs}"
      --check-cache-status
      --flake
      --gc-roots-dir $GC_ROOTS_DIR
      --max-memory-size $MAX_MEMORY_SIZE
      $1
  }

  "${lib.getExe jq}" -r "select(.isCached | not).attr"
''
