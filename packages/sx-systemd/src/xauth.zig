// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const child = @import("child.zig");
const env = @import("env.zig");

pub fn add(allocator: std.mem.Allocator, env_map: *const std.process.EnvMap) !void {
    const display = try env.get(env_map, "DISPLAY");

    var buf: [32]u8 = undefined;
    const argv = [_][]const u8{ "xauth", "-v", "add", display, "MIT-MAGIC-COOKIE-1", hexkey(&buf) };
    std.log.debug("argv: {s}", .{argv});

    try child.run(.{
        .allocator = allocator,
        .argv = &argv,
        .env_map = env_map,
    });
}

test "add" {
    var alloc = std.testing.allocator;

    var env_map = std.process.EnvMap.init(alloc);
    defer env_map.deinit();

    var tmpDir = std.testing.tmpDir(.{});
    defer tmpDir.cleanup();

    const parent_path = try tmpDir.dir.realpathAlloc(alloc, ".");
    defer alloc.free(parent_path);

    const xauthority = try std.fs.path.join(alloc, &[_][]const u8{ parent_path, "Xauthority" });
    defer alloc.free(xauthority);

    try env_map.put("DISPLAY", ":9");
    try env_map.put("XAUTHORITY", xauthority);

    var ret: anyerror!void = undefined;

    const read_stdout_fd, const write_stdout_fd = try std.posix.pipe();
    const read_stderr_fd, const write_stderr_fd = try std.posix.pipe();

    const max_output_bytes = 50 * 1024;
    var poller = std.io.poll(alloc, enum { stdout, stderr }, .{
        .stdout = std.fs.File{ .handle = read_stdout_fd },
        .stderr = std.fs.File{ .handle = read_stderr_fd },
    });
    defer poller.deinit();

    const fork_pid = try std.posix.fork();
    if (fork_pid == 0) {
        try std.posix.dup2(write_stdout_fd, 1);
        try std.posix.dup2(write_stderr_fd, 2);
        std.posix.close(read_stdout_fd);
        std.posix.close(read_stderr_fd);
        defer std.posix.close(write_stdout_fd);
        defer std.posix.close(write_stderr_fd);

        ret = add(alloc, &env_map);
        std.process.exit(0);
    }

    defer std.posix.close(read_stdout_fd);
    defer std.posix.close(read_stderr_fd);
    std.posix.close(write_stdout_fd);
    std.posix.close(write_stderr_fd);

    while (try poller.poll()) {
        if (poller.fifo(.stdout).count > max_output_bytes)
            return error.StdoutStreamTooLong;
        if (poller.fifo(.stderr).count > max_output_bytes)
            return error.StderrStreamTooLong;
    }

    std.log.debug("stdout: {s}", .{poller.fifo(.stdout).readableSlice(0)});
    std.log.debug("stderr: {s}", .{poller.fifo(.stderr).readableSlice(0)});

    try std.testing.expectEqual(0, std.posix.waitpid(fork_pid, 0).status);
    try ret;
}

pub fn remove(allocator: std.mem.Allocator, env_map: *const std.process.EnvMap) !void {
    const display = try env.get(env_map, "DISPLAY");

    const argv = [_][]const u8{ "xauth", "-v", "remove", display };
    std.log.debug("argv: {s}", .{argv});

    try child.run(.{
        .allocator = allocator,
        .argv = &argv,
        .env_map = env_map,
    });
}

fn hexkey(buf: []u8) []const u8 {
    const hexkeyLen = 16;
    std.debug.assert(buf.len >= hexkeyLen * 2);

    const rand = std.crypto.random;
    rand.bytes(buf[0..hexkeyLen]);

    @memcpy(buf[0 .. hexkeyLen * 2], &std.fmt.bytesToHex(buf[0..hexkeyLen], .lower));

    return buf[0 .. hexkeyLen * 2];
}

test "hexkey" {
    var buf: [32]u8 = undefined;
    const got = hexkey(&buf);
    try std.testing.expect(!std.mem.eql(u8, "a" ** 32, got));
}
