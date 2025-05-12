// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const config = @import("config");

const dbus = @import("dbus.zig");
const env = @import("env.zig");
const stty = @import("stty.zig");
const xauth = @import("xauth.zig");
const xinit = @import("xinit.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var env_map = try env.getMap(allocator);
    defer env_map.deinit();

    std.log.debug("env_map: {??s}", .{env.fmtEnvMap(env_map)});

    // const xdg_runtime_dir = try env.get(&env_map, "XDG_RUNTIME_DIR");
    // {
    //     // const xdg_vtnr = try env.get(&env_map, "XDG_VTNR");
    //     const tty = try env.get(&env_map, "GPG_TTY");

    //     const stty_setting = stty.get(allocator);
    //     std.log.debug("stty_setting: {s}", .{stty_setting});

    //     var dir = try std.fs.openDirAbsolute(xdg_runtime_dir, .{});
    //     defer dir.close();
    //     const file = try dir.createFile("stty-restore.env", .{});
    //     defer file.close();

    //     try std.fmt.format(file.writer(), "DEVICE='{s}'\n", .{tty});
    //     try std.fmt.format(file.writer(), "SETTING='{s}'\n", .{stty_setting});
    //     // const pfx = "stty";
    //     // var path: [64]u8 = undefined;
    //     // @memcpy(path[0..pfx.len], pfx);
    //     // @memcpy(path[pfx.len .. pfx.len + xdg_vtnr.len], xdg_vtnr);
    //     // const file = try dir.createFile(path[0 .. pfx.len + xdg_vtnr.len], .{});
    //     // try stty.save(allocator, file.writer());
    // }

    try xauth.add(allocator, &env_map);
    try dbus.updateEnvVars(allocator, &env_map, &env.changed);
    try xinit.run(allocator, &env_map);
}

test {
    std.testing.log_level = @enumFromInt(@intFromEnum(config.test_log_level));
    std.testing.refAllDecls(@This());
}
