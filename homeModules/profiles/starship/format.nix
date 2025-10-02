# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ config, lib, ... }:
let
  cfg = config.programs.starship;
in
{
  programs.starship.settings =
    let
      upstreamNoEmptySymbols = lib.importTOML "${cfg.package}/share/starship/presets/no-empty-icons.toml";
    in
    lib.mkMerge [
      (
        lib.importTOML "${cfg.package}/share/starship/presets/no-empty-icons.toml"
        |> builtins.mapAttrs (
          _: v: { format = builtins.replaceStrings [ "via " "with " ] [ "" "" ] v.format; }
        )
      )

      {
        format =
          ''$username$hostname$localip$shlvl$singularity$kubernetes$directory$vcsh$fossil_branch$fossil_metrics$git_branch$git_commit$git_state$git_metrics$git_status$hg_branch$pijul_channel$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$gleam$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$quarto$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$typst$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$nats$direnv$env_var$mise$crystal$custom$sudo$cmd_duration''
          + ''$line_break$jobs$battery$time$status$os$container$netns([: $shell;](white bold))$character'';

        cmd_duration.format = "[󱦟$duration]($style)";
        custom.continuation.format = "([$symbol$output;]($style) )";
        hostname.format = "[$hostname]($style) ";
        nix_shell.format = "([$symbol$state(\\($name)\\)]($style) )";
        nix_shell.impure_msg = "";
        shell.format = "$indicator";
        shlvl.format = "[$shlvl$symbol]($style)";
        username.format = "[$user]($style)@";
      }
    ];
}
