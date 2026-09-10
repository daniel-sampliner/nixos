# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "nixos-configs";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    dgx.url = "gitlab:dsampliner/nix-config?host=gitlab-master.nvidia.com";
    dgx.flake = false;

    flake-compat.url = "github:NixOS/flake-compat";
    flake-compat.flake = false;

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;

      imports = [
        ./devShell.nix
        ./home
        ./nixpkgs.nix
        ./treefmt.nix
      ];

      systems = [ "x86_64-linux" ];
    };
}
