# SPDX-FileCopyrightText: 2025 Adam M. Joseph <adam@westernsemico.com>
#
# SPDX-License-Identifier: MIT

{ lib }:
{
  isNonFunctorAttrs = v: (builtins.isAttrs v) && !(builtins.isFunction v);

  throw-error =
    {
      path ? null,
      func,
      msg,
    }:
    let
      where = lib.strings.optionalString (path != null) "at path ${lib.attrsets.showAttrPath path}: ";
    in
    throw "infuse.${func}: ${where}${msg}";
}
