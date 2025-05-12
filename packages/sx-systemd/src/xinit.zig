// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const env = @import("env.zig");

pub fn run(allocator: std.mem.Allocator, env_map: *const std.process.EnvMap) !void {
    const display = try allocator.dupeZ(u8, try env.get(env_map, "DISPLAY"));
    defer allocator.free(display);

    const vtnr = try std.mem.concatWithSentinel(allocator, u8, &[_][]const u8{ "vt", try (env.get(env_map, "XDG_VTNR")) }, 0);
    defer allocator.free(vtnr);

    const xauthority = try allocator.dupeZ(u8, try env.get(env_map, "XAUTHORITY"));
    defer allocator.free(xauthority);

    const argv = [_:null]?[*:0]const u8{
        "systemd-cat",
        "-t",
        "xinit",
        "xinit",
        "--",
        display,
        vtnr,
        "-auth",
        xauthority,
        "-nolisten",
        "tcp",
        "-noreset",
        "-logfile",
        "/dev/null",
        "-verbose",
        "3",
    };
    std.log.debug("argv: {???s}", .{&argv});

    const envp = try std.process.createEnvironFromMap(allocator, env_map, .{});

    const err = std.posix.execvpeZ(argv[0].?, &argv, envp);
    std.log.err("failed to execvpeZ {???s}", .{&argv});
    return err;
}
