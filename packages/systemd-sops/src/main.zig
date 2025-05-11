// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");

const TestExtras = @import("./TestExtras.zig");

// const buffer_size = std.fs.MAX_PATH_BYTES;
const buffer_size = 256;

pub const std_options = .{
    .logFn = switch (builtin.mode) {
        .Debug => std.log.defaultLog,
        .ReleaseFast => syslogFn,
        .ReleaseSafe => syslogFn,
        .ReleaseSmall => syslogFn,
    },
};

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

test {
    std.testing.log_level = @enumFromInt(@intFromEnum(config.test_log_level));
    std.testing.refAllDecls(@This());
}

pub fn main() !void {
    var sops_file_idx: usize = 0;
    var sops_file: [buffer_size:0]u8 = undefined;

    if (std.posix.getenv("SOPS_BASE_DIR")) |sops_base_dir| {
        const print = try std.fmt.bufPrintZ(&sops_file, "{s}/", .{sops_base_dir});
        sops_file_idx = print.len;
    } else {
        std.log.err("Missing required environment variable SOPS_BASE_DIR", .{});
        return error.InvalidConfiguration;
    }
    // sops_file[sops_file_idx] = '/';
    std.log.debug("sops_file: {s}", .{std.fmt.fmtSliceEscapeLower(sops_file[0..sops_file_idx :0])});

    const key = try credInfoFromSocketFD(0, sops_file[sops_file_idx..]);
    sops_file_idx += key.len;
    // _ = try std.fmt.bufPrintZ(sops_file[sops_file_idx..], "{s}", .{key});
    std.log.debug("sops_file: {s}", .{std.fmt.fmtSliceEscapeLower(sops_file[0..sops_file_idx :0])});

    try execSops(sops_file[0..sops_file_idx :0], .{ .age_key_file = blk: {
        if (std.posix.getenv("CREDENTIALS_DIRECTORY")) |cred_dir| {
            var buf: [buffer_size:0]u8 = undefined;
            break :blk try std.fmt.bufPrintZ(&buf, "{s}/age_key", .{cred_dir});
        } else {
            break :blk null;
        }
    } });
}

fn credInfoFromSocketFD(fd: std.posix.socket_t, buffer: []u8) ![]u8 {
    const log = std.log.scoped(.credInfoFromSocketFD);

    var addr = std.posix.sockaddr.un{ .path = undefined };
    var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.un);

    try std.posix.getpeername(fd, @ptrCast(&addr), &addr_len);

    switch (builtin.mode) {
        .Debug => {
            if (addr.family != std.posix.AF.UNIX) {
                switch (addr.family) {
                    std.posix.AF.INET => log.err("fd {} is INET socket", .{fd}),
                    std.posix.AF.INET6 => log.err("fd {} is INET6 socket", .{fd}),
                    else => log.err("fd {} is unknown {} socket", .{ fd, addr.family }),
                }

                return error.SocketNotUnix;
            }

            if (addr.path[0] != 0) {
                return error.UnixSocketNotAbstract;
            }
        },
        else => {
            std.debug.assert(addr.path[0] == 0);
        },
    }

    const abstract_address = addr.path[1..];
    log.debug("abstract_address: {s}", .{std.fmt.fmtSliceEscapeLower(abstract_address)});

    const end = std.mem.indexOfScalar(u8, abstract_address, 0) orelse abstract_address.len;
    const key = std.fs.path.basename(abstract_address[0..end]);

    return std.fmt.bufPrintZ(buffer, "{s}", .{key});
}

test "credInfoFromSocketFD" {
    const log = std.log.scoped(.test_credInfoFromSocketFD);

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

    const cred_info = "key";
    const client_thread = try std.Thread.spawn(
        .{ .allocator = allocator },
        TestExtras.socketConnect,
        .{ allocator, cred_info, &listen_socket_path },
    );
    defer client_thread.join();

    const connection = try server.accept();
    var buffer: [@sizeOf(std.posix.sockaddr.un)]u8 = undefined;
    const cred_info_got = try credInfoFromSocketFD(connection.stream.handle, &buffer);
    log.debug("cred_info_got: {s}", .{cred_info_got});
    try std.testing.expectEqualStrings(cred_info, cred_info_got);
}

fn execSops(
    sops_file: [:0]const u8,
    options: struct { age_key_file: ?[:0]const u8 = null },
) !void {
    const log = std.log.scoped(.execSops);

    log.debug("sops_file: {s}", .{std.fmt.fmtSliceEscapeLower(sops_file)});

    const argv = [_:null]?[*:0]const u8{ "sops", "--decrypt", sops_file };
    log.debug("argv: {??s}", .{argv});

    const envp = [_:null]?[*:0]const u8{if (options.age_key_file) |age_key_file| blk: {
        var buf: [buffer_size:0]u8 = undefined;
        break :blk try std.fmt.bufPrintZ(&buf, "SOPS_AGE_KEY_FILE={s}", .{age_key_file});
    } else null};
    log.debug("envp: {???s}", .{envp});

    const err = std.posix.execvpeZ(argv[0].?, &argv, &envp);

    log.err("failed to execvpeZ '{??s}'", .{argv});
    return err;
}

test "execSops" {
    const log = std.log.scoped(.test_execSops);

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_dir = try std.fs.cwd().openDir("test", .{});

    const realpathAllocZ = (struct {
        pub fn realpathAllocZ(self: std.fs.Dir, alloc: std.mem.Allocator, pathname: [:0]const u8) ![:0]u8 {
            var buf: [std.fs.MAX_PATH_BYTES:0]u8 = undefined;
            return alloc.dupeZ(u8, try self.realpathZ(pathname, &buf));
        }
    }).realpathAllocZ;

    const age_key_file = try realpathAllocZ(test_dir, allocator, "age.priv");
    const sops_file = try realpathAllocZ(test_dir, allocator, "file.sops");
    log.debug("age_key_file: {s}", .{age_key_file});
    log.debug("sops_file: {s}", .{sops_file});

    var ret: @TypeOf(execSops("", .{})) = undefined;

    const read_fd, const write_fd = try std.posix.pipe();
    const fork_pid = try std.posix.fork();

    if (fork_pid == 0) {
        try std.posix.dup2(write_fd, 1);
        std.posix.close(read_fd);
        defer std.posix.close(write_fd);

        ret = execSops(sops_file, .{ .age_key_file = age_key_file });
        // ret = execSops(sops_file, .{});
        std.process.exit(0);
    }

    defer std.posix.close(read_fd);
    std.posix.close(write_fd);

    const reader = (std.fs.File{ .handle = read_fd }).reader();
    const max_output_bytes = 50 * 1024;
    var fbs_buffer: [max_output_bytes]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&fbs_buffer);
    reader.streamUntilDelimiter(fbs.writer(), 0, fbs_buffer.len) catch |err| switch (err) {
        error.EndOfStream => {},

        else => {
            log.err("failed to read subprocess stdout: {}", .{err});
            return err;
        },
    };

    try ret;

    const stdout = fbs.getWritten();
    log.debug("stdout: \"{s}\"", .{std.fmt.fmtSliceEscapeLower(stdout)});

    try std.testing.expectEqual(0, std.posix.waitpid(fork_pid, 0).status);
    try std.testing.expectEqualStrings("hello world!\n", stdout);
}
