// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");

const TestExtras = @import("./TestExtras.zig");

pub const std_options = .{
    .logFn = switch (builtin.mode) {
        .Debug => std.log.defaultLog,
        .ReleaseFast => syslogFn,
        .ReleaseSafe => syslogFn,
        .ReleaseSmall => syslogFn,
    },
};

test {
    std.testing.log_level = @enumFromInt(@intFromEnum(config.test_log_level));
}

/// Print log in syslog(3) format. Adapated from std.log.defaultLog.
pub fn syslogFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .err => "<3>",
        .warn => "<4>",
        .info => "<6>",
        .debug => "<7>",
    };

    const prefix2 = if (scope == .default) "" else "(" ++ @tagName(scope) ++ ")";
    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "", args) catch return;
        bw.flush() catch return;
    }
}

pub fn main() !void {
    // const sops_base_dir: [:0]const u8 = try (std.posix.getenv("SOPS_BASE_DIR") orelse blk: {
    //     std.log.err("Missing required environment variable SOPS_BASE_DIR", .{});
    //     break :blk error.InvalidConfiguration;
    // });
    // std.log.debug("sops_base_dir: {s}", .{sops_base_dir});

    var buffer: [@sizeOf(std.posix.sockaddr.un)]u8 = undefined;
    const cred_info = try credInfoFromSocket(0, &buffer);
    std.log.debug("cred_info: {s}", .{cred_info});

    {
        const writer = std.io.getStdOut().writer();
        try writer.print("{s}", .{cred_info});
    }
    // var sops_file: [std.fs.MAX_PATH_BYTES:0]u8 = undefined;
    // try (socketToSOPS(&sops_file, 0))

    // var cmd = [_:null]?[*:0]const u8{ "echo".ptr, key[0..:0].ptr  };
    // cmd = cmd;
    // std.log.debug("{any}", .{cmd});

    // var args = [_:null]?[*:0]const u8{ "hello", "goodbye", null };
    // const env = [_:null]?[*:0]u8{null};
    // return std.posix.execvpeZ("echo", args, env);
    // const writer = std.io.getStdOut().writer();
    // try writer.print("{s}", .{key});
}

fn credInfoFromSocket(fd: std.posix.socket_t, buffer: []u8) ![]u8 {
    const log = std.log.scoped(.credInfoFromSocket);

    var addr = std.posix.sockaddr.un{ .path = undefined };
    var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.un);

    try std.posix.getpeername(fd, @ptrCast(&addr), &addr_len);

    if (addr.family != std.posix.AF.UNIX) {
        return error.SocketNotUnix;
    }
    if (addr.path[0] != 0) {
        return error.UnixSocketNotAbstract;
    }

    const abstract_address = addr.path[1..];

    const end_idx = try (std.mem.indexOfScalar(u8, abstract_address, 0) orelse error.InvalidPeerName);
    const first_slash_idx = try (std.mem.indexOfScalar(u8, abstract_address, '/') orelse error.InvalidPeerName);
    const begin_idx = try (std.mem.indexOfScalarPos(u8, abstract_address, first_slash_idx + 1, '/') orelse error.InvalidPeerName);

    const length = end_idx - begin_idx;
    if (length < 4) {
        return error.InvalidPeerName;
    }

    const ret = buffer[0..length];
    @memcpy(ret, abstract_address[begin_idx..end_idx]);
    log.debug("ret: {0s} {0any}", .{ret});

    return ret;
}

test "credInfoFromSocket" {
    const log = std.log.scoped(.test_credInfoFromSocket);

    if (builtin.single_threaded) {
        log.warn("test not supported in single-threaded mode", .{});
        return error.SkipZigTest;
    }

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var listen_socket_path: [TestExtras.random_string_len + 1]u8 = undefined;
    listen_socket_path[0] = 0;
    _ = TestExtras.randomString(listen_socket_path[1..]);

    const server_addr = try std.net.Address.initUnix(&listen_socket_path);
    var server = try std.net.Address.listen(server_addr, .{});
    defer server.deinit();
    log.debug("listen_socket_path: {0s} {0any}", .{listen_socket_path});
    log.debug("server: {}", .{server});

    const cred_info = "service/key";
    const client_thread = try std.Thread.spawn(
        .{ .allocator = allocator },
        TestExtras.socketConnect,
        .{ allocator, cred_info, &listen_socket_path },
    );
    defer client_thread.join();

    const connection = try server.accept();
    var buffer: [@sizeOf(std.posix.sockaddr.un)]u8 = undefined;
    const cred_info_got = try credInfoFromSocket(connection.stream.handle, &buffer);
    log.debug("cred_info_got: {s}", .{cred_info_got});
    try std.testing.expectEqualStrings("/" ++ cred_info, cred_info_got);
}

test "sopsFile" {
    const log = std.log.scoped(.sopsFile);

    const sops_base_dir: [:0]const u8 = "/sops";
    const cred_info: []u8 = blk: {
        const name = "/service/key";
        var array: [name.len]u8 = name.*;
        break :blk &array;
    };
    log.debug("sops_base_dir: {s}", .{sops_base_dir});
    log.debug("cred_info: {s}", .{cred_info});

    var sops_file: [std.fs.MAX_PATH_BYTES:0]u8 = undefined;
    @memset(&sops_file, 0);
    {
        var begin_idx: usize = 0;
        var end_idx: usize = sops_base_dir.len;
        @memcpy(sops_file[begin_idx..end_idx], sops_base_dir);

        begin_idx = end_idx;
        end_idx = begin_idx + cred_info.len;
        @memcpy(sops_file[begin_idx..end_idx], cred_info);
    }

    log.debug("sops_file: {s} {any}", .{ sops_file, sops_file[0..32] });

    const read_fd, const write_fd = try std.posix.pipe();
    const fork_pid = try std.posix.fork();

    if (fork_pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "echo".ptr, &sops_file };
        const envp = [_:null]?[*:0]const u8{null};
        try std.posix.dup2(write_fd, 1);
        std.posix.close(read_fd);
        const ret = std.posix.execvpeZ(argv[0].?, &argv, &envp);
        log.err("failed to execvpeZ: {any}", .{ret});
        std.process.exit(1);
    }

    std.posix.close(write_fd);

    const reader = (std.fs.File{ .handle = read_fd }).reader();

    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    try reader.streamUntilDelimiter(fbs.writer(), '\n', buffer.len);
    const stdout = fbs.getWritten();

    const ret = std.posix.waitpid(fork_pid, 0);

    try std.testing.expectEqual(0, ret.status);
    try std.testing.expectEqualStrings(std.mem.sliceTo(&sops_file, 0), stdout);
}

fn sopsFile(buf: [:0]u8, socket_path: []const u8, sops_base_dir: []const u8) !void {
    const key = std.fs.path.basename(socket_path);
    const unit = try if (std.fs.path.dirname(socket_path)) |dir|
        std.fs.path.basename(dir)
    else blk: {
        std.log.err("Could not parse unit from socket path {s}", .{socket_path});
        break :blk error.CantParseUnit;
    };

    var begin: usize = 0;
    var end: usize = sops_base_dir.len;
    @memcpy(buf[begin..end], sops_base_dir);
    buf[end] = '/';
    end += 1;

    begin = end;
    end += unit.len;
    @memcpy(buf[begin..end], unit);
    buf[end] = '/';
    end += 1;

    begin = end;
    end += key.len;
    @memcpy(buf[begin..end], key);

    buf[end] = 0;
    return;
}
