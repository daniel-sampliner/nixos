# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos-configs";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-25.05/nixexprs.tar.xz";
    unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "unstable";

    dgx.url = "gitlab:dsampliner/nix-config?host=gitlab-master.nvidia.com";
    dgx.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;

      imports = [
        ./devshell.nix
        ./home
        ./treefmt.nix
      ];

      systems = [ "x86_64-linux" ];
    };
}
