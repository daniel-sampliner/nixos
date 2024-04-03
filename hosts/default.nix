# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../users
    ./profiles/nix.nix
    ./profiles/shells.nix
  ];

  boot = {
    ephemeral.enable = lib.mkDefault true;
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  environment.systemPackages =
    let
      terminals = builtins.attrValues {
        inherit (pkgs)
          alacritty
          dvtm
          kitty
          st
          ;
      };
      getTerminfo = t: t.terminfo or (mkTerminfo t);
      mkTerminfo =
        t:
        pkgs.runCommand (lib.getName t) { } ''
          mkdir -p "$out/share/terminfo"
          cp -r "${t}/share/terminfo" "$out/share"
        '';
    in
    lib.pipe terminals [
      (builtins.map getTerminfo)
      (builtins.map pkgs.hiPrio)
    ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  programs.git.enable = true;
  programs.git.package = pkgs.gitMinimal;

  services = {
    openssh.enable = true;

    timesyncd = {
      enable = lib.mkDefault true;
      servers = [ ];

      extraConfig = ''
        FallbackNTP=time1.google.com time2.google.com time3.google.com time4.google.com
      '';
    };
  };

  systemd.network.wait-online.anyInterface =
    config.networking.useDHCP
    || lib.pipe config.systemd.network.networks [
      (lib.mapAttrsToList (_: v: v.DHCP))
      (builtins.map (d: d != null && d != "no"))
      (lib.any lib.id)
    ];

  time.timeZone = lib.mkDefault "America/New_York";

  virtualisation.vmVariant = {
    boot.kernelParams = [ "boot.shell_on_fail" ];

    system.activationScripts = {
      injectSOPSKey = ''
        install -Dm 0400 "${./build-vm.ssh_host_ed25519_key}" "${config.sops.key}"
      '';

      sopsUserPasswords.deps = [ "injectSOPSKey" ];
    };
  };
}
