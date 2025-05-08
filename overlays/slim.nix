# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

final: prev:
let
  inherit (prev) lib;
in
lib.infuse prev {
  dbusSupport = _: false;
  systemdSupport = _: false;
  udevSupport = _: false;

  cairo.__input.x11Support = _: false;
  dbus.__input.x11Support = _: false;
  ffmpeg.__input.ffmpegVariant = _: "headless";
  ffmpeg_4.__input.ffmpegVariant = _: "headless";
  ffmpeg_6.__input.ffmpegVariant = _: "headless";
  ffmpeg_7.__input.ffmpegVariant = _: "headless";
  gd.__input.withXorg = _: false;
  gobject-introspection.__input.x11Support = _: false;
  graphviz = _: prev.graphviz-nox;

  gst_all_1 = {
    gst-plugins-bad.__input.guiSupport = _: false;

    gst-plugins-base.__input = {
      enableGl = _: false;
      enableWayland = _: false;
      enableX11 = _: false;
    };

    gst-plugins-good.__input = {
      enableWayland = _: false;
      enableX11 = _: false;
      gtkSupport = _: false;
      qt5Support = _: false;
      qt6Support = _: false;
    };

    gst-plugins-rs.__input.withGtkPlugins = _: false;
  };

  imagemagick.__input = {
    libX11Support = _: false;
    libXtSupport = _: false;
  };

  imagemagickBig.__input = {
    libX11Support = _: false;
    libXtSupport = _: false;
  };

  jellyfin-ffmpeg.__input.ffmpeg_7-full =
    _:
    prev.ffmpeg_7-headless.override {
      withAvisynth = true;
      withFdkAac = true;
      withOpenh264 = true;
      withRav1e = true;
    };

  libva = _: prev.libva-minimal;
  pango.__input.x11Support = _: false;

  pipewire.__input = {
    vulkanSupport = _: false;
    x11Support = _: false;
  };

  qt6 =
    qt6:
    qt6.overrideScope (
      _: prev': {
        qtbase =
          let
            nullAttrs = builtins.mapAttrs (_: _: null);
          in
          lib.trivial.pipe prev'.qtbase [
            (
              qtbase:
              qtbase.override {
                at-spi2-core = null;
                cups = null;
                dbus = null;
                fontconfig = null;
                freetype = null;
                gtk3 = null;
                harfbuzz = null;
                libGL = null;
                libX11 = null;
                libXcomposite = null;
                libXext = null;
                libXi = null;
                libXrender = null;
                libepoxy = null;
                libinput = null;
                libmysqlclient = prev.emptyFile;
                libxcb = null;
                libxkbcommon = null;
                qttranslations = null;
                unixODBC = null;
                unixODBCDrivers = nullAttrs prev.unixODBCDrivers;
                vulkan-loader = prev.emptyFile;
                xcbutil = null;
                xcbutilimage = null;
                xcbutilkeysyms = null;
                xcbutilrenderutil = null;
                xcbutilwm = null;
                xorg = nullAttrs prev.xorg;

                withGtk3 = false;
              }
            )

            (
              qtbase:
              let
                fArgs = lib.functionArgs qtbase.override;
              in
              qtbase.override (
                lib.mergeAttrsList [
                  (lib.optionalAttrs (fArgs ? "libGLSupported") { libGLSupported = false; })
                  (lib.optionalAttrs (fArgs ? "libpq") { libpq = null; })
                  (lib.optionalAttrs (fArgs ? "postgresql") { postgresql = null; })
                ]
              )
            )

            (
              qtbase:
              qtbase.overrideAttrs (prev'': {
                cmakeFlags = prev''.cmakeFlags or [ ] ++ [
                  "-DQT_FEATURE_dbus=off"
                  "-DQT_FEATURE_gui=off"
                ];

                postFixup =
                  let
                    s = "patchelf --add-rpath \"${prev.emptyFile}";
                  in
                  builtins.replaceStrings [ s ] [ ": ${s}" ] (prev''.postFixup or "");
              })
            )
          ];

        qtlanguageserver = prev.emptyFile;
        qtshadertools = prev.emptyFile;
        qtsvg = prev.emptyFile;
        wrapQtAppsHook = prev'.wrapQtAppsNoGuiHook;
      }
    );

  util-linux.__input.translateManpages = _: false;
  wayland.__input.withDocumentation = _: false;
  wrapGAppsHook3 = _: prev.wrapGAppsNoGuiHook;
  wrapGAppsHook4.__input.isGraphical = _: false;
}
