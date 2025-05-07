# SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ lib, infuse }:
let
  upstream = import ./infuse-upstream.nix { inherit lib; };
  inherit (upstream) isNonFunctorAttrs throw-error;

  inherit (import infuse { inherit lib; }) v1;
  my-infuse = import infuse {
    inherit lib;
    sugars =
      let
        my-sugars = {
          __extend =
            path: infusion:
            if isNonFunctorAttrs infusion then
              target:
              my-sugars.__extend path (_: previousAttrs: lib.flip v1.infuse path infusion previousAttrs) target
            else if builtins.isFunction infusion then
              target:
              if builtins.isFunction target then
                arg: infusion (target arg)
              else if builtins.isAttrs target && target ? extend then
                target.extend (
                  final: prev:
                  let
                    applied = infusion final;
                  in
                  if (!builtins.isFunction applied) then
                    throw-error {
                      inherit path;
                      func = "extend";
                      msg = "when infusing to drv.__extend you must pass a *two*-curried funcction (i.e., `__output = finalAttrs: previousAttrs: ...`)";
                    }
                  else
                    applied prev
                )
              else
                throw-error {
                  inherit path;
                  func = "extend";
                  msg = "attempted to infuse to __extend of an unsupported type: ${builtins.typeOf target}";
                }
            else
              throw-error {
                inherit path;
                func = "extend";
                msg = "applied to unsupported type: ${builtins.typeOf infusion}";
              };
        };
      in
      v1.default-sugars ++ lib.attrsets.attrsToList my-sugars;
  };
in
{
  inherit (my-infuse) v1;
}
