// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const child = @import("child.zig");

pub fn get(allocator: std.mem.Allocator) []const u8 {
    const argv = [_][]const u8{ "stty", "-g" };
    const stdout = child.runStdout(.{ .allocator = allocator, .argv = &argv }) catch "sane";
    return std.mem.trimRight(u8, stdout, "\n");
}

pub fn set(allocator: std.mem.Allocator, settings: []const u8) !void {
    const argv = [_][]const u8{ "stty", settings };
    try child.run(.{ .allocator = allocator, .argv = &argv });
}

pub fn save(allocator: std.mem.Allocator, writer: anytype) !void {
    const argv = [_][]const u8{ "stty", "-g" };
    try child.runWriteStdout(writer, .{ .allocator = allocator, .argv = &argv });
}
