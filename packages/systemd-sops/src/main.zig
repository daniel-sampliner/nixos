// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");

const TestExtras = @import("./TestExtras.zig");

const buffer_size = 128;

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
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}

pub fn main() !void {
    var sops_file_idx: usize = 0;
    // var sops_file: [std.fs.MAX_PATH_BYTES:0]u8 = undefined;
    var sops_file: [buffer_size:0]u8 = undefined;
    @memset(&sops_file, 0);

    if (std.posix.getenv("SOPS_BASE_DIR")) |sops_base_dir| {
        sops_file_idx = sops_base_dir.len;
        @memcpy(sops_file[0..sops_file_idx], sops_base_dir.ptr);
    } else {
        std.log.err("Missing required environment variable SOPS_BASE_DIR", .{});
        return error.InvalidConfiguration;
    }
    std.log.debug("sops_file: {s}", .{sops_file});

    _ = try credInfoFromSocket(0, sops_file[sops_file_idx..]);
    std.log.debug("sops_file: {s}", .{sops_file});

    return execSops(&sops_file, .{ .command = "echo" });
}

fn credInfoFromSocket(fd: std.posix.socket_t, buffer: []u8) ![]u8 {
    const log = std.log.scoped(.credInfoFromSocket);

    var addr = std.posix.sockaddr.un{ .path = undefined };
    var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.un);

    try std.posix.getpeername(fd, @ptrCast(&addr), &addr_len);

    if (addr.family != std.posix.AF.UNIX) {
        switch (addr.family) {
            std.posix.AF.INET => log.err("fd {} is INET socket", .{fd}),
            std.posix.AF.INET6 => log.err("fd {} is INET6 socket", .{fd}),
            else => log.err("fd {} is {} socket", .{ fd, addr.family }),
        }

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

fn execSops(
    sops_file: [:0]const u8,
    options: struct { command: [:0]const u8 = "sops" },
) anyerror {
    const log = std.log.scoped(.execSops);

    const argv = [_:null]?[*:0]const u8{ options.command.ptr, "--decrypt".ptr, sops_file.ptr };
    log.debug("argv: {any}", .{argv});
    for (argv, 0..) |arg, idx| {
        std.log.debug("  {}: {?s}", .{ idx, arg });
    }

    const sops_age_key_file_env = "SOPS_AGE_KEY_FILE";
    // var buffer: [std.fs.MAX_PATH_BYTES + sops_age_key_file_env.len + 1:0]u8 = undefined;
    var buffer: [buffer_size:0]u8 = undefined;
    @memset(&buffer, 0);
    @memcpy(buffer[0..sops_age_key_file_env.len], sops_age_key_file_env.ptr);
    buffer[sops_age_key_file_env.len] = '=';

    const envp = [_:null]?[*:0]const u8{
        if (std.posix.getenv(sops_age_key_file_env)) |e| blk: {
            @memcpy(buffer[sops_age_key_file_env.len + 1 ..][0..e.len], e);
            break :blk std.mem.sliceTo(&buffer, 0);
        } else null,

        null,
    };

    std.log.debug("envp: {any}", .{envp});
    for (envp, 0..) |env, idx| {
        log.debug("  {}: {?s}", .{ idx, env });
    }

    const err = std.posix.execvpeZ(argv[0].?, &argv, &envp);

    log.err("failed to execvpeZ '{?s}'", .{argv[0]});
    return err;
}

test "execSops" {
    const log = std.log.scoped(.execSops);

    var sops_file: [std.fs.MAX_PATH_BYTES:0]u8 = undefined;
    @memset(&sops_file, 0);
    {
        const s = "/sops/service/key";
        @memcpy(sops_file[0..s.len], s);
    }

    const read_fd, const write_fd = try std.posix.pipe();
    const fork_pid = try std.posix.fork();

    if (fork_pid == 0) {
        try std.posix.dup2(write_fd, 1);
        std.posix.close(read_fd);
        std.posix.close(write_fd);
        execSops(&sops_file, .{ .command = "echo" }) catch {};

        std.process.exit(1);
    }

    std.posix.close(write_fd);
    defer std.posix.close(read_fd);

    const reader = (std.fs.File{ .handle = read_fd }).reader();

    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    reader.streamUntilDelimiter(fbs.writer(), '\n', buffer.len) catch |err| switch (err) {
        error.EndOfStream => {},
        else => log.err("failed to read subprocess stdout: {}", .{err}),
    };

    const ret = std.posix.waitpid(fork_pid, 0);
    try std.testing.expectEqual(0, ret.status);

    const stdout = fbs.getWritten();
    try std.testing.expectEqualStrings(std.mem.sliceTo(&sops_file, 0), stdout);
}
