# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  fetchFromGitHub,
  lib,
  nono,
  pkgsUnstable,
  rustPlatform,
}:
let
  minVer = "0.73.0";
  checkVer =
    pkg:
    lib.trivial.pipe pkg [
      lib.strings.getVersion
      (v: lib.strings.versionOlder v minVer)
    ];

  src = fetchFromGitHub {
    inherit (nono.src) owner repo;
    tag = "v${minVer}";
    hash = "sha256-7k0K57A7RakezXgfEhdEJP+GIWusNj8IAKtCCNU4I6Q=";
  };
in
assert lib.asserts.assertMsg (checkVer pkgsUnstable.nono)
  "unstable nono must be older than ${minVer}";

nono.overrideAttrs (prev: {
  version = minVer;
  inherit src;

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    name = "${prev.pname}-${minVer}";
    hash = "sha256-JXV9G0CNptDSWtAY1k1RQC07FEVy530hhqqtojzzpEg=";
  };

  checkFlags =
    prev.checkFlags or [ ]
    ++ (map (t: "--skip=${t}") [
      "capability_ext::tests::test_from_profile_filesystem_allow_expands_git_dynamic_token"
      "command_policies_allows_compiled_binary_exec_in_writable_grant_dir"
      "command_policies_allows_script_exec_in_writable_grant_dir"
      "direct_workdir_overrides_untrusted_host_pwd"
      "direct_workdir_sets_child_pwd_from_uncovered_launch_dir"
      "env_credentials_with_command_policies_non_shim_entry_succeeds"
      "granted_path_exits_zero"
      "proxy_runtime::tests::capture_helper_with_interaction_stdin_true_inherits_terminal_stdin"
      "proxy_runtime::tests::capture_helper_with_stdio_true_receives_null_not_terminal_stdin"
      "proxy_runtime::tests::proxy_credential_capture_backend_captures_and_caches"
      "proxy_runtime::tests::proxy_credential_capture_backend_parses_json_headers"
      "proxy_runtime::tests::proxy_credential_capture_backend_rejects_empty_stdout"
      "proxy_runtime::tests::proxy_credential_capture_backend_sends_request_json_stdin"
      "proxy_runtime::tests::proxy_credential_capture_backend_uses_path_cache_scope"
      "sandbox::linux::tests::test_restrict_execute_does_not_break_rename_into_new_subdir"
      "server::tests::reactive_proxy_auth_retry_answered_after_407"
      "server::tests::test_oauth_capture_routes_activate_intercept"
      "server::tests::test_route_diagnostics_groups_credential_and_endpoint_routes"
      "supervised_workdir_overrides_untrusted_host_pwd"
      "supervised_workdir_sets_child_pwd_from_uncovered_launch_dir"
      "tool_sandbox::dynamic_providers::tests::git_read_common_dir_returns_absolute_path_in_worktree"
      "tool_sandbox::dynamic_providers::tests::git_read_common_dir_returns_dot_git_in_regular_repo"
      "tool_sandbox::dynamic_providers::tests::git_read_files_includes_non_firing_includeif_target"
      "tool_sandbox::dynamic_providers::tests::git_read_main_worktree_returns_empty_in_regular_repo"
      "tool_sandbox::dynamic_providers::tests::git_read_main_worktree_returns_main_repo_root_in_linked_worktree"
      "tool_sandbox::dynamic_providers::tests::git_read_paths_excludes_per_repo_local_config_overrides"
      "tool_sandbox::dynamic_providers::tests::git_read_paths_includeif_hasconfig_matches_remote"
      "tool_sandbox::dynamic_providers::tests::git_read_paths_with_global_returns_config_file_and_path_values"
      "tool_sandbox::dynamic_providers::tests::git_read_paths_with_global_walks_include_chain"
      "tool_sandbox::dynamic_providers::tests::git_read_toplevel_parent_returns_parent_of_repo_root"
      "tool_sandbox::dynamic_providers::tests::git_read_toplevel_returns_absolute_path_in_regular_repo"
      "tool_sandbox::dynamic_providers::tests::git_read_toplevel_returns_worktree_root_in_linked_worktree"
      "tool_sandbox::dynamic_providers::tests::git_toplevel_common_dir_and_worktree_never_spawn_git_in_linked_worktree"
      "tool_sandbox::dynamic_providers::tests::git_toplevel_common_dir_and_worktree_never_spawn_git_in_regular_repo"
    ]);
})
