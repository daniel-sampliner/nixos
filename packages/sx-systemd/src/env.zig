// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

pub const changed = [_][]const u8{ "DISPLAY", "XAUTHORITY" };

pub fn getMap(allocator: std.mem.Allocator) !std.process.EnvMap {
    var env = try std.process.getEnvMap(allocator);

    const xdg_runtime_dir = try get(&env, "XDG_RUNTIME_DIR");
    const xdg_vtnr = try get(&env, "XDG_VTNR");

    var display: [64]u8 = undefined;
    display[0] = ':';
    @memcpy(display[1 .. xdg_vtnr.len + 1], xdg_vtnr);
    try env.put("DISPLAY", display[0 .. xdg_vtnr.len + 1]);

    // {
    //     const pfx = "/dev/tty";
    //     var gpg_tty: [64]u8 = undefined;
    //     @memcpy(gpg_tty[0..pfx.len], pfx);
    //     @memcpy(gpg_tty[pfx.len .. pfx.len + xdg_vtnr.len], xdg_vtnr);
    //     try env.put("GPG_TTY", gpg_tty[0 .. pfx.len + xdg_vtnr.len]);
    // }

    const sfx = "/Xauthority";
    var xauthority: [std.posix.PATH_MAX]u8 = undefined;
    @memcpy(xauthority[0..xdg_runtime_dir.len], xdg_runtime_dir);
    @memcpy(xauthority[xdg_runtime_dir.len .. xdg_runtime_dir.len + sfx.len], sfx);
    try env.put("XAUTHORITY", xauthority[0 .. xdg_runtime_dir.len + sfx.len]);

    return env;
}

test "getMap" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const want = &[_][]const u8{
        try std.fmt.allocPrintZ(arena_alloc, ":{s}", .{std.posix.getenv("XDG_VTNR").?}),
        try std.fmt.allocPrintZ(arena_alloc, "{s}/Xauthority", .{std.posix.getenv("XDG_RUNTIME_DIR").?}),
    };

    var env_map = try getMap(allocator);
    defer env_map.deinit();

    std.log.debug("env_map: {??s}", .{fmtEnvMap(env_map)});

    for (changed, 0..) |env, idx| {
        try std.testing.expectEqualStrings(want[idx], try get(&env_map, env));
    }
}

pub fn get(env_map: *const std.process.EnvMap, key: []const u8) ![]const u8 {
    if (env_map.get(key)) |v| {
        return v;
    } else {
        std.log.err("{s} not set!", .{key});
        return error.MissingEnvVar;
    }
}

pub fn fmtEnvMap(em: std.process.EnvMap) std.fmt.Formatter(formatEnvMap) {
    return .{ .data = em };
}

pub fn formatEnvMap(
    em: std.process.EnvMap,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    try writer.writeAll("{ ");
    for (changed, 0..) |e, idx| {
        try writer.writeAll(e);
        try writer.writeAll("=");
        try std.fmt.formatType(em.get(e), fmt, options, writer, std.options.fmt_max_depth - 1);
        if (idx < changed.len - 1) {
            try writer.writeAll(", ");
        }
    }
    try writer.writeAll(" }");
}
