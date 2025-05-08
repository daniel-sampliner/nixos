# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    flake-compat.url = "github:nix-community/flake-compat";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "unstable";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";

    infuse.url = "https://codeberg.org/amjoseph/infuse.nix/archive/trunk.tar.gz";
    infuse.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = builtins.attrValues { inherit (flake-utils.lib.system) x86_64-linux; };
    in
    {
      lib = import ./lib { inherit lib self; };
      nixosModules = self.lib.collectDirAttrs { } ./nixosModules;
      overlays = import ./overlays { inherit lib self; };
    }
    // flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = self.lib.mkNixpkgs nixpkgs system { overlays = [ self.overlays.default ]; };
        self' = pkgs.flakePackages.self;
        treefmtConfiguration = treefmt-nix.lib.evalModule pkgs.pkgsUnstable ./treefmt.nix;
      in
      {
        inherit treefmtConfiguration;

        # Uncomment for debugging overlays
        # legacyPackages = pkgs;

        checks = import ./checks {
          inherit pkgs self';
          inherit (pkgs) lib;
        };

        containers = import ./containers {
          inherit pkgs self';
          inherit (pkgs) lib;
        };

        devShells.default = import ./devShell.nix { inherit lib pkgs self'; };
        formatter = treefmtConfiguration.config.build.wrapper;
        packages = lib.attrsets.filterAttrs (_: lib.attrsets.isDerivation) pkgs.flakePackages;
      }
    );
}
