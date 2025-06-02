// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");
const sqlite_ext = @import("sqlite-ext.zig");

const config = @import("config");

pub fn generate(seed: i64, writer: anytype) !void {
    var prng = std.Random.DefaultPrng.init(@bitCast(seed));
    const rand = prng.random();

    try writer.print("<ul>\n", .{});
    defer writer.print("</ul>\n", .{}) catch {};

    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = config.words_db },
    });
    defer db.deinit();

    try sqlite_ext.init(&db);

    const query =
        \\SELECT word FROM words ORDER BY randoms(?) LIMIT 64
    ;
    var stmt = try db.prepare(query);
    defer stmt.deinit();

    var iter = try stmt.iterator([64:0]u8, .{seed});

    for (0..rand.intRangeAtMost(u8, 4, 8)) |_| {
        try writer.print("<li>", .{});
        defer writer.print("</li>\n", .{}) catch {};

        try writer.print("<a href=\"", .{});
        defer writer.print("</a>", .{}) catch {};
        {
            defer writer.print("\">", .{}) catch {};
            for (0..rand.intRangeAtMost(u8, 1, 4)) |_| {
                const word = (try iter.next(.{})).?;
                try writer.print("/{s}", .{word[0..].ptr});
            }
        }
        const word = (try iter.next(.{})).?;
        try writer.print("{s}", .{word[0..].ptr});
    }
}
