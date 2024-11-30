# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
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
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "unstable";
    };

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { flakelight, ... }@inputs:
    let
      inherit (inputs.nixpkgs) lib;

      nixDir = ./flakelight;
      extraModules = builtins.attrValues (flakelight.lib.importDir "${nixDir}/flakelightModules");
    in
    flakelight.lib.mkFlake.extend extraModules ./. {
      inherit inputs nixDir;

      flakelight.editorconfig = false;
      nixpkgs.config.allowUnfree = true;

      # Workaround for Dotnet SDK 6.x EOL
      nixpkgs.config.allowInsecurePredicate =
        pkg:
        builtins.elem (lib.getName pkg) (
          lib.concatMap
            (n: [
              n
              "${n}-wrapped"
            ])
            [
              "aspnetcore-runtime"
              "dotnet-sdk"
            ]
        )
        && lib.hasPrefix "6." (lib.getVersion pkg);

      systems = [ "x86_64-linux" ];
    };
}
