# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  writers,

  gh,
  gitMinimal,
}:
writers.writeExecline
  {
    runtimeInputs = [
      gh
      gitMinimal
    ];
  }
  "/bin/gh-commit"
  ''
    multisubstitute {
      importas -iu BRANCH BRANCH
      importas -iu COMMIT_HEADLINE COMMIT_HEADLINE
      importas -iu GITHUB_REPOSITORY GITHUB_REPOSITORY

      importas -u COMMIT_BODY_FILE COMMIT_BODY_FILE
    }

    backtick -E tmpdir { mktemp -d --tmpdir gh-raise-pr.XXXXX }
    if { eltest -n $tmpdir }
    if { eltest -d $tmpdir }

    foreground {
      backtick args {
        pipeline { git status --porcelain=v2 }
        pipeline { grep "^1 " }
        forstdin -E -o 0 -C line
          multidefine $line { "" "" "" "" "" "" "" "" path }
          backtick -E dir { dirname $path }
          if { mkdir -p ''${tmpdir}/''${dir} }
          if { redirfd -w 1 ''${tmpdir}/''${path} base64 -w0 $path }
          echo -F "files[][path]=''${path}" -F "files[][contents]=@''${tmpdir}/''${path}"
      }
      importas -iu -s args' args

      backtick -E head { git rev-parse HEAD }

      if {
        if { gh api graphql
          -F githubRepository=$GITHUB_REPOSITORY
          -F branchName=$BRANCH
          -F expectedHeadOid=$head
          -F commitHeadline=$COMMIT_HEADLINE
          -FcommitBody=@$COMMIT_BODY_FILE
          $args'
          -F query=@${./createCommitOnBranch.gqls} }
        echo
      }
    }

    importas -iu ret ?
    foreground { rm -rf -- $tmpdir }
    exit $ret
  ''
