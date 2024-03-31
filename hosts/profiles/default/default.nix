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
  imports = [ ./nix.nix ];

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
      (builtins.map (p: lib.setPrio ((p.meta.priority or 5) + 3) p))
    ];

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

  sops.userPasswords.root = ./passwd.sops;

  time.timeZone = lib.mkDefault "America/New_York";

  virtualisation.vmVariant = {
    boot.kernelParams = [ "boot.shell_on_fail" ];

    sops.userPasswords.root = lib.mkVMOverride ./build-vm.passwd.sops;

    system.activationScripts = {
      injectSOPSKey = ''
        install -Dm 0400 "${./build-vm.ssh_host_ed25519_key}" "${config.sops.key}"
      '';

      sopsUserPasswords.deps = [ "injectSOPSKey" ];
    };
  };
}
