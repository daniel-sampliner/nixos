// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");

pub fn run(args: struct {
    allocator: std.mem.Allocator,
    argv: []const []const u8,
    env_map: ?*const std.process.EnvMap = null,
}) !void {
    var child = std.process.Child.init(args.argv, args.allocator);
    child.env_map = args.env_map;

    const ret = try child.spawnAndWait();

    const logfn = comptime if (builtin.is_test) std.log.debug else std.log.err;
    return switch (ret) {
        .Exited => |r| if (r == 0) {} else blk: {
            logfn("{s} exited with {d}", .{ args.argv, r });
            break :blk error.CmdFailed;
        },

        inline else => blk: {
            logfn("{s} failed with {any}", .{ args.argv, ret });
            break :blk error.CmdFailed;
        },
    };
}

test "run_true" {
    try run(.{ .allocator = std.testing.allocator, .argv = &[_][]const u8{"true"} });
}

test "run_false" {
    try std.testing.expectError(
        error.CmdFailed,
        run(.{ .allocator = std.testing.allocator, .argv = &[_][]const u8{"false"} }),
    );
}

pub fn runStdout(args: struct {
    allocator: std.mem.Allocator,
    argv: []const []const u8,
    env_map: ?*const std.process.EnvMap = null,
}) ![]const u8 {
    var child = std.process.Child.init(args.argv, args.allocator);
    child.env_map = args.env_map;
    child.stdout_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(args.allocator);
    errdefer stdout.deinit();

    try child.spawn();
    try collectStdout(child, &stdout);

    const term = try child.wait();
    return switch (term) {
        .Exited => |ret| if (ret == 0) try stdout.toOwnedSlice() else blk: {
            std.log.err("{s} exited with {d}", .{ args.argv, ret });
            break :blk error.CmdFailed;
        },

        inline else => blk: {
            std.log.err("{s} failed with {any}", .{ args.argv, term });
            break :blk error.CmdFailed;
        },
    };
}

pub fn collectStdout(child: std.process.Child, stdout: *std.ArrayList(u8)) !void {
    const max_output_bytes: usize = 50 * 1024;

    var poller = std.io.poll(stdout.allocator, enum { stdout }, .{ .stdout = child.stdout.? });
    defer poller.deinit();

    while (try poller.poll()) {
        if (poller.fifo(.stdout).count > max_output_bytes)
            return error.StdoutStreamTooLong;
    }

    stdout.* = fifoToOwnedArrayList(poller.fifo(.stdout));
}

fn fifoToOwnedArrayList(fifo: *std.io.PollFifo) std.ArrayList(u8) {
    if (fifo.head > 0) {
        @memcpy(fifo.buf[0..fifo.count], fifo.buf[fifo.head..][0..fifo.count]);
    }
    const result = std.ArrayList(u8){
        .items = fifo.buf[0..fifo.count],
        .capacity = fifo.buf.len,
        .allocator = fifo.allocator,
    };
    fifo.* = std.io.PollFifo.init(fifo.allocator);
    return result;
}

pub fn runWriteStdout(writer: anytype, args: struct {
    allocator: std.mem.Allocator,
    argv: []const []const u8,
}) !void {
    var fifo = std.fifo.LinearFifo(u8, .{ .Static = 1024 }).init();

    var child = std.process.Child.init(args.argv, args.allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();

    try fifo.pump(child.stdout.?.reader(), writer);

    const term = try child.wait();
    return switch (term) {
        .Exited => |ret| if (ret == 0) {} else blk: {
            std.log.err("{s} exited with {d}", .{ args.argv, ret });
            break :blk error.CmdFailed;
        },

        inline else => blk: {
            std.log.err("{s} failed with {any}", .{ args.argv, term });
            break :blk error.CmdFailed;
        },
    };
}
