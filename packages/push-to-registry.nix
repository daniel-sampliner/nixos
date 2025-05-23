# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  inputs',
  writers,
}:
writers.writeExecline
  {
    runtimeInputs = builtins.attrValues {
      inherit (inputs'.nix2container.packages) nix2container-bin skopeo-nix2container;
    };
  }
  "/bin/push-to-registry"
  ''
    multisubstitute {
      importas -i GH_TOKEN GH_TOKEN
      importas -i GITHUB_ACTOR GITHUB_ACTOR
      importas -i GITHUB_REF_NAME GITHUB_REF_NAME
      importas -i GITHUB_SHA GITHUB_SHA
      importas -i INSTALLABLE INSTALLABLE
    }

    backtick -E repository { nix eval --raw ''${INSTALLABLE}.meta.repository }
    backtick -E registry { heredoc 0 $repository cut -d/ -f1 }
    backtick -E github_ref_name_safe { heredoc 0 $GITHUB_REF_NAME tr -cs "[:alnum:]-\n" "-" }

    if {
      heredoc -d 0 $GH_TOKEN
      skopeo login
        --username $GITHUB_ACTOR
        --password-stdin
        $registry
    }

    if {
      forx -o 0 -E t { $GITHUB_SHA $github_ref_name_safe }
      nix run ''${INSTALLABLE}.copyTo -- --retry-times 5 "docker://''${repository}:''${t}"
    }

    ifelse
      { eltest $GITHUB_REF_NAME = main }
      {
        pipeline { nix eval --json ''${INSTALLABLE}.meta.tags }
        pipeline { jq -r .[] }
        forstdin -o 0 -E tag
        nix run ''${INSTALLABLE}.copyTo -- --retry-times 5 "docker://''${repository}:''${tag}"
      }
    exit 0
  ''
