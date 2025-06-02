// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const builtin = @import("builtin");
const std = @import("std");

const config = @import("config");
const test_config = @import("test_config");

const sqlite = @import("sqlite");

const bomb = @import("bomb.zig");
const gcra = @import("gcra.zig");
const links = @import("links.zig");
const markov = @import("markov.zig");

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .ReleaseFast => .info,
        else => std.log.default_level,
    },
};

test {
    std.testing.log_level = @enumFromInt(@intFromEnum(test_config.test_log_level));
    std.testing.refAllDecls(@This());
}

pub fn main() !void {
    const now = std.time.milliTimestamp();

    const seed: i64 = blk: {
        const day = @divTrunc(std.time.timestamp(), 60 * 60 * 24);
        const host = std.posix.getenv("SERVER_NAME") orelse "unknown";
        const uri = std.posix.getenv("REQUEST_URI") orelse "/unknown";
        std.log.debug("host: {s}", .{host});
        std.log.debug("uri: {s}", .{uri});
        var hasher = std.hash.XxHash3.init(@bitCast(day));
        hasher.update(host);
        hasher.update(uri);
        break :blk @bitCast(hasher.final());
    };

    std.log.debug("seed: {d}", .{seed});

    const xff = blk: {
        const xffs = std.posix.getenv("HTTP_X_FORWARDED_FOR") orelse break :blk null;
        var it = std.mem.tokenizeAny(u8, xffs, ", ");
        break :blk it.next();
    } orelse "unknown";

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Content-Type: text/html\n", .{});
    try stdout.print("Transfer-Encoding: chunked\n", .{});

    const encoding = std.posix.getenv("HTTP_ACCEPT_ENCODING");
    if (std.posix.getenv("HTTP_X_GIVE_ME_THE_HEAT")) |_| {
        try bomb.deliver(stdout, encoding);
    }

    switch (config.zipbomb) {
        .no => {},
        .always => {
            try bomb.deliver(stdout, encoding);
        },
        .yes => {
            const user_agent = std.posix.getenv("HTTP_USER_AGENT") orelse "";
            var it = std.mem.tokenizeAny(u8, user_agent, " \t");
            if (it.rest().len < 1 or !try gcra.conforming(xff, now)) {
                try bomb.deliver(stdout, encoding);
            }
        },
    }

    // try stdout.print("Cache-Control: no-store, no-transform\n", .{});
    // try stdout.print("Cache-Control: no-store\n", .{});
    try stdout.print("Cache-Control: max-age={d}, no-transform, public\n", .{60 * 60 * 24});
    try stdout.print("\n", .{});
    try bw.flush();

    defer bw.flush() catch {};
    try stdout.print("<html>\n", .{});
    defer stdout.print("</html>\n", .{}) catch {};

    {
        try stdout.print("<head>\n", .{});
        defer stdout.print("</head>\n", .{}) catch {};
        try stdout.print("<meta name=\"robots\" content=\"none\" />\n", .{});
    }

    try stdout.print("<body>\n", .{});
    defer stdout.print("</body>\n", .{}) catch {};

    {
        try stdout.print("<p> ", .{});
        defer stdout.print("</p>\n", .{}) catch {};
        try markov.words(256, seed, stdout);
    }

    try links.generate(seed, stdout);

    if (config.throttle) {
        var idx: usize = 0;
        const writer = bw.unbuffered_writer;

        if (config.initial_write_bytes > 0) {
            const bytes = @min(config.initial_write_bytes, bw.end);
            try writer.print("{s}", .{bw.buf[0..bytes]});
            idx += bytes;
        }

        var prng = std.Random.DefaultPrng.init(blk: {
            var seed_b: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed_b));
            break :blk seed_b;
        });
        const rand = prng.random();

        const offset = idx;
        idx = 0;

        while (offset + idx < bw.end) {
            const bytes = rand.intRangeAtMost(u64, 1, @min(8, bw.end - offset - idx));
            try writer.print("{s}", .{bw.buf[offset + idx .. offset + idx + bytes]});
            idx += bytes;

            const wait = rand.intRangeAtMost(
                u64,
                1,
                @min(
                    1000 * std.math.pow(u64, 10, 6),
                    idx * std.math.pow(u64, 10, 6),
                ),
            );
            // std.log.debug("idx: {d}\t wait: {d}", .{ idx, std.fmt.fmtDuration(wait) });
            std.time.sleep(wait);
        }
        bw.end = 0;
    }
}
