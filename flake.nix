# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos-configs";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    nixpkgs_cacert.url = "github:nixos/nixpkgs/43a7ae3f9e374f1fde09022c81d4fb1326a67f60";
    nixpkgs_release.url = "github:nixos/nixpkgs/98bca2b5be256ebd2489df073e794b558483ae20";

    dgx.url = "gitlab:dsampliner/nix-config?host=gitlab-master.nvidia.com";
    dgx.flake = false;

    flake-compat.url = "github:NixOS/flake-compat";
    flake-compat.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./containers.nix
        ./devShell.nix
        ./github.nix
        ./home
        ./nixpkgs.nix
        ./treefmt.nix
      ];

      systems = [ "x86_64-linux" ];
    };
}
