// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const child = @import("child.zig");

pub fn updateEnvVars(allocator: std.mem.Allocator, env_map: *const std.process.EnvMap, env_vars: []const []const u8) !void {
    const argv = try std.mem.concat(allocator, []const u8, &[_][]const []const u8{
        &[_][]const u8{ "dbus-update-activation-environment", "--systemd", "--verbose" },
        env_vars,
    });
    defer allocator.free(argv);
    std.log.debug("argv: {s}", .{argv});

    try child.run(.{
        .allocator = allocator,
        .argv = argv,
        .env_map = env_map,
    });
}
