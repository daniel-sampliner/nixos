// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");

const sqlite_ext = @import("sqlite-ext.zig");

pub fn words(length: u32, seed: i64, writer: anytype) !void {
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "markov.db" },
    });
    defer db.deinit();

    try sqlite_ext.init(&db);

    const query =
        \\WITH RECURSIVE
        \\  start AS (
        \\      SELECT
        \\          *,
        \\          CASE substr(w1, 1, 1)
        \\              WHEN '\x22' THEN 2
        \\              WHEN '\x27' THEN 2
        \\              ELSE 1
        \\          END idx
        \\      FROM markov
        \\      WHERE substr(w1, idx, 1) BETWEEN 'A' AND 'Z'
        \\      ORDER BY randoms($seed)
        \\      LIMIT 1
        \\  ),
        \\
        \\  text(w1, w2, next) AS (
        \\      SELECT w1, w2, next FROM start
        \\      UNION ALL
        \\      SELECT
        \\          text.w2,
        \\          text.next,
        \\          (
        \\              SELECT markov.next
        \\              FROM markov
        \\              WHERE markov.w1 == text.w2 AND markov.w2 == text.next
        \\              ORDER BY randoms($seed)
        \\              LIMIT 1
        \\          )
        \\      FROM text
        \\      LIMIT $limit
        \\  )
        \\SELECT w1 FROM text
    ;

    var stmt = try db.prepare(query);
    defer stmt.deinit();

    var iter = try stmt.iterator([256:0]u8, .{ .seed = seed, .limit = length * 3 / 2 });
    for (0..length) |_| {
        if (try iter.next(.{})) |word| {
            try writer.print("{s} ", .{word[0..].ptr});
        } else {
            break;
        }
    } else {
        while (try iter.next(.{})) |word| {
            try writer.print("{s} ", .{word[0..].ptr});
            switch (word[std.mem.indexOfSentinel(u8, 0, &word) - 1]) {
                inline '.', '!', '?' => {
                    break;
                },
                else => {},
            }
        }
    }
}
