// SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

module.exports = async (installables, { core, exec }) => {
  await Promise.all(
    Object.entries(installables).map(([output, installable]) =>
      setOutputToAttrNames(output, installable, { core, exec }),
    ),
  );
};

async function setOutputToAttrNames(output, installable, { core, exec }) {
  const ret = await exec.getExecOutput("nix", [
    "eval",
    "--json",
    installable,
    "--apply",
    "builtins.attrNames",
  ]);
  const names = JSON.parse(ret.stdout);
  if (!Array.isArray(names) || names.length === 0)
    throw new Error(`nix eval ${installable} had no output`);
  core.setOutput(output, JSON.stringify(names));
}
