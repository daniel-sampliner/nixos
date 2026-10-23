// SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} env not set`);
  }
  return value;
}

module.exports = requireEnv;
