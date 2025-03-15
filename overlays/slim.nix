# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

_: prev:
let
  inherit (prev) lib;
in
{
  dbusSupport = false;
  systemdSupport = false;
  udevSupport = false;

  cairo = prev.cairo.override { x11Support = false; };
  dbus = prev.dbus.override { x11Support = false; };
  ffmpeg = prev.ffmpeg.override { ffmpegVariant = "headless"; };
  ffmpeg_4 = prev.ffmpeg_4.override { ffmpegVariant = "headless"; };
  ffmpeg_6 = prev.ffmpeg_6.override { ffmpegVariant = "headless"; };
  ffmpeg_7 = prev.ffmpeg_7.override { ffmpegVariant = "headless"; };
  gd = prev.gd.override { withXorg = false; };
  gobject-introspection = prev.gobject-introspection.override { x11Support = false; };
  graphviz = prev.graphviz-nox;

  gst_all_1 = prev.gst_all_1 // {
    gst-plugins-bad = prev.gst_all_1.gst-plugins-bad.override { guiSupport = false; };

    gst-plugins-base = prev.gst_all_1.gst-plugins-base.override {
      enableGl = false;
      enableWayland = false;
      enableX11 = false;
    };

    gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
      enableWayland = false;
      enableX11 = false;
      gtkSupport = false;
      qt5Support = false;
      qt6Support = false;
    };

    gst-plugins-rs = prev.gst_all_1.gst-plugins-rs.override { withGtkPlugins = false; };
  };

  imagemagick = prev.imagemagick.override {
    libX11Support = false;
    libXtSupport = false;
  };

  imagemagickBig = prev.imagemagickBig.override {
    libX11Support = false;
    libXtSupport = false;
  };

  jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
    ffmpeg_7-full = prev.ffmpeg_7-headless.override {
      withAvisynth = true;
      withFdkAac = true;
      withOpenh264 = true;
      withRav1e = true;
    };
  };

  libva = prev.libva-minimal;
  pango = prev.pango.override { x11Support = false; };

  pipewire = prev.pipewire.override {
    vulkanSupport = false;
    x11Support = false;
  };

  qt6 = prev.qt6.overrideScope (
    _: prev': {
      qtbase =
        let
          nullAttrs = builtins.mapAttrs (_: _: null);
        in
        lib.pipe prev'.qtbase [
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

  util-linux = prev.util-linux.override { translateManpages = false; };
  wayland = prev.wayland.override { withDocumentation = false; };
  wrapGAppsHook3 = prev.wrapGAppsNoGuiHook;
  wrapGAppsHook4 = prev.wrapGAppsHook4.override { isGraphical = false; };
}
