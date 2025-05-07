# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, self }:
lib.composeManyExtensions [
  self.inputs.devshell.overlays.default

  (_: prev: {
    flakePackages = self.lib.mkScope prev ./packages;

    pkgsUnstable = self.lib.mkNixpkgs self.inputs.unstable prev.system {
      overlays = [
        self.overlays.default
        (_: _: { pkgsUnstable = null; })
      ];
    };
  })

  (
    _: prev:
    let
      inherit (prev) flakePackages;
      assignAttrs = builtins.mapAttrs (_: lib.const);
    in
    self.lib.infuse prev (
      {
        lib = _: flakePackages.lib;
        vimPlugins.__extend = (_: _: flakePackages.vimPlugins-extra.passthru.plugins);

        writers = lib.pipe flakePackages.writers-extra [
          (lib.attrsets.filterAttrs (n: _: lib.strings.hasPrefix "write" n))
          assignAttrs
        ];
      }
      // assignAttrs flakePackages.passthru.packages
    )
  )
]
