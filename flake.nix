# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  description = "nixos configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    impermanence.url = "github:nix-community/impermanence";

    devshell = {
      url = "github:numtide/devshell";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs.follows = "unstable";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { flakelight, ... }:
    flakelight ./. {
      nixDir = ./flakelight;
      nixpkgs.config.allowUnfree = true;
      systems = [ "x86_64-linux" ];
    };
}
