# SPDX-FileCopyrightText: 2024 - 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "unstable";

    gradle2nix = {
      url = "github:tadfisher/gradle2nix/v2";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "unstable";
    };

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs =
    { flakelight, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;
      myLib = import ./lib.nix { inherit lib; };
    in
    flakelight.lib.mkFlake ./. {
      inherit inputs;

      flakelight.editorconfig = false;
      imports = myLib.collectDir { } ./flakelightModules;
      legacyPackages = lib.id;
      nixDir = ./.;
      systems = [ "x86_64-linux" ];

      withOverlays = [
        inputs.devshell.overlays.default
        (_: prev: { pkgsSlim = prev.extend prev.moduleArgs.config.overlays.slim; })
      ];
    };
}
