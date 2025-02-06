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
  "/bin/gh-raise-pr"
  ''
    multisubstitute {
      importas -iu APP_SLUG APP_SLUG
      importas -iu BRANCH BRANCH
      importas -iu COMMIT_HEADLINE COMMIT_HEADLINE
      importas -iu GITHUB_REPOSITORY GITHUB_REPOSITORY

      importas -u COMMIT_BODY_FILE COMMIT_BODY_FILE
    }

    backtick -E user_id { gh api "/users/''${APP_SLUG}[bot]" --jq .id }
    if { eltest -n $app_slug }

    if { git config --local user.name "''${APP_SLUG}[bot}" }
    if { git config --local user.email "''${user_id}+''${APP_SLUG}[bot]@users.noreply.github.com" }

    if { git switch -C $BRANCH HEAD }
    if { git push --set-upstream origin --force $BRANCH }

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
    ifelse { eltest $ret != 0 } { exit $ret }

    if { git stash }
    if { git pull }

    pipeline { git log -1 --format=%b }
    ifelse
      {
        redirfd -r 0 /dev/null
        backtick -E closed { gh pr view --json closed --jq .closed }
        eltest $closed = false
      }
      { gh pr edit --title $COMMIT_HEADLINE --body-file - }
    gh pr create --title $COMMIT_HEADLINE --body-file -
  ''
