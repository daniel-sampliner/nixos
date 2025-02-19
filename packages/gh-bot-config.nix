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
  "/bin/gh-bot-config"
  ''
    importas -iu APP_SLUG APP_SLUG
    if { eltest -n APP_SLUG }

    define user_name "''${APP_SLUG}[bot]"

    backtick -E user_id { gh api "/users/''${user_name}" --jq .id }
    if { eltest -n $user_id }

    if { git config --local user.name "''${user_name}" }
    git config --local user.email "''${user_id}+''${user_name}@users.noreply.github.com"
  ''
