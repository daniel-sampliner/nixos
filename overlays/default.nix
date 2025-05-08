# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, self }:
let
  default = lib.composeManyExtensions [
    self.inputs.devshell.overlays.default
    (_: prev: { inherit (self.inputs.nix2container.packages.${prev.system}) nix2container; })

    (_: prev: {
      flakePackages = self.lib.mkScope prev (self + "/packages");

      pkgsUnstable = self.lib.mkNixpkgs self.inputs.unstable prev.system {
        overlays = [
          self.overlays.default
          (_: _: { pkgsUnstable = null; })
        ];
      };

      pkgsSlim = prev.extend self.overlays.slim;
    })

    (
      final: prev:
      let
        inherit (prev) flakePackages;
        assignAttrs = builtins.mapAttrs (_: lib.const);
      in
      self.lib.infuse prev (
        {
          lib = _: flakePackages.lib;
          vimPlugins.__extend = (_: _: flakePackages.vimPlugins-extra.passthru.plugins);

          writers = lib.trivial.pipe flakePackages.writers-extra [
            (lib.attrsets.filterAttrs (n: _: lib.strings.hasPrefix "write" n))
            assignAttrs
          ];
        }
        // assignAttrs flakePackages.passthru.packages
        // import ./containers.nix final prev
      )
    )
  ];

  slim = import ./slim.nix;
in
{
  inherit default slim;
}
