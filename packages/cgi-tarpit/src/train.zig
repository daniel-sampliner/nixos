// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const stdin_file = std.io.getStdIn();

    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "markov.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
    });
    defer db.deinit();

    try db.exec("BEGIN TRANSACTION", .{}, .{});
    try db.exec(
        \\CREATE TABLE IF NOT EXISTS markov(
        \\  w1 TEXT,
        \\  w2 TEXT,
        \\  next TEXT
        \\) STRICT
    ,
        .{},
        .{},
    );
    try db.exec(
        "CREATE INDEX IF NOT EXISTS words on markov(w1, w2)",
        .{},
        .{},
    );

    var stmt = try db.prepare("INSERT INTO markov VALUES($w1, $w2, $next)");
    defer stmt.deinit();

    var w1 = std.ArrayList(u8).init(arena);
    var w2 = std.ArrayList(u8).init(arena);
    var line = std.ArrayList(u8).init(arena);
    var quote = std.ArrayList(u8).init(arena);
    const quote_writer = quote.writer();
    while (stdin_file.reader().streamUntilDelimiter(line.writer(), '\n', 1024 * 1024)) {
        defer line.clearRetainingCapacity();

        var iter = std.mem.tokenizeAny(u8, line.items, " \t");
        while (iter.next()) |word| {
            if (quote.items.len < 1) {
                switch (word[0]) {
                    '"', '\'' => {
                        const idx = closingQuoteIdx(word);
                        if (word[idx] != word[0]) {
                            try quote_writer.print("{s}", .{word});
                            continue;
                        }
                    },
                    else => {},
                }
                stmt.reset();
                try stmt.exec(.{}, .{ w1.items, w2.items, word });
                try w1.resize(w2.items.len);
                @memcpy(w1.items, w2.items);
                try w2.resize(word.len);
                @memcpy(w2.items, word);
            } else {
                try quote_writer.print(" {s}", .{word});
                const idx = closingQuoteIdx(word);
                if (word[idx] == quote.items[0]) {
                    stmt.reset();
                    try stmt.exec(.{}, .{ w1.items, w2.items, quote.items });
                    try w1.resize(w2.items.len);
                    @memcpy(w1.items, w2.items);
                    try w2.resize(quote.items.len);
                    @memcpy(w2.items, quote.items);
                    quote.clearRetainingCapacity();
                }
            }
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    try db.exec("COMMIT", .{}, .{});
}

fn closingQuoteIdx(word: []const u8) usize {
    var idx = word.len - 1;
    if (idx > 0) {
        switch (word[idx]) {
            '.', ',', '!', '?', ':', '&' => {
                idx -= 1;
            },
            else => {},
        }
    }

    return idx;
}
