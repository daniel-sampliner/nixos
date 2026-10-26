# SPDX-FileCopyrightText: 2026 Daniel Sampliner <samplinerD@gmail.com>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{ pi-coding-agent }:
pi-coding-agent.overrideAttrs (prev: {
  pname = prev.pname + "-chatgpt-account-id";

  patches = prev.patches or [ ] ++ [ ./0001-feat-ai-support-Codex-account-ID-overrides.patch ];
})
