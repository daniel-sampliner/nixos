// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const random_bytes_count = 12;
pub const random_string_len = std.fs.base64_encoder.calcSize(random_bytes_count);

pub fn randomString(buffer: []u8) []const u8 {
    var random_bytes: [random_bytes_count]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);

    return std.fs.base64_encoder.encode(buffer, &random_bytes);
}

pub fn socketConnect(allocator: std.mem.Allocator, cred_info: []const u8, path: []const u8) !void {
    const log = std.log.scoped(.socketConnect);

    const sockfd = try std.posix.socket(
        std.posix.AF.UNIX,
        std.posix.SOCK.STREAM | std.posix.SOCK.CLOEXEC,
        0,
    );
    defer std.net.Stream.close(.{ .handle = sockfd });
    try ioctl_FIONREAD(sockfd);
    _ = try std.posix.fcntl(sockfd, std.posix.F.SETFD, std.posix.FD_CLOEXEC);

    log.debug("cred_info: {0s} {0any}", .{cred_info});

    var nameBase: [random_string_len]u8 = undefined;
    _ = randomString(&nameBase);

    const name = try std.mem.concat(allocator, u8, &[_][]const u8{ "\x00", &nameBase, "/unit/service/", cred_info });
    log.debug("name: {0s} {0any}", .{name});

    const addr = try std.net.Address.initUnix(name);
    try std.posix.bind(
        sockfd,
        &addr.any,
        @truncate(@sizeOf(std.posix.sa_family_t) + name.len),
    );

    const remote_addr = try std.net.Address.initUnix(path);
    try std.posix.connect(sockfd, &remote_addr.any, remote_addr.getOsSockLen());
}

fn ioctl_FIONREAD(fd: std.posix.fd_t) !void {
    var arg: usize = 0;
    while (true) {
        switch (std.posix.errno(std.os.linux.ioctl(fd, std.posix.T.FIONREAD, @intFromPtr(&arg)))) {
            .SUCCESS => return,
            .INVAL => unreachable,
            .NOTTY => return error.NotATerminal,
            .PERM => return error.AccessDenied,
            else => |err| return std.posix.unexpectedErrno(err),
        }
    }
}
