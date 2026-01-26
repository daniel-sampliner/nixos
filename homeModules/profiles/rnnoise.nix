# SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, pkgs, ... }:
{
  xdg.configFile."pipewire/pipewire.conf.d/99-rnnoise.conf".text = builtins.toJSON {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";

        args = {
          "node.description" = "Noise Cancelling source";
          "media.name" = "Noise Cancelling source";

          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "${lib.getLib pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";

                control = {
                  "VAD Threshold (%)" = 50.0;
                  "VAD Grace Period (ms)" = 200;
                  "Retroactive VAD Grace (ms)" = 0;
                };
              }
            ];
          };

          "capture.props" = {
            "audio.rate" = 48000;
            "node.name" = "capture.rnnoise_source";
            "node.passive" = true;
          };

          "playback.props" = {
            "audio.channels" = 1;
            "audio.position" = [ "MONO" ];
            "audio.rate" = 48000;
            "filter.name" = "rnnoise_source";
            "filter.smart" = true;
            "media.class" = "Audio/Source";
            "node.name" = "rnnoise_source";
          };
        };
      }
    ];
  };
}
