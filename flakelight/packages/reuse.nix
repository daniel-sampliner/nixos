# SPDX-FileCopyrightText: 2024 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: GLWTPL

{
  inputs',
  fetchpatch,
  reuse,
}:
reuse.overrideAttrs (prev: {
  inherit (inputs'.unstable.legacyPackages.reuse) name src version;

  patches = prev.patches or [ ] ++ [
    (fetchpatch {
      url = "https://github.com/fsfe/reuse-tool/pull/909.patch";
      hash = "sha256-wWgBHw1XUuMur9Wi/3xPdj4wMfMsRH0E26xQP1DzcHA=";
    })
  ];
})
