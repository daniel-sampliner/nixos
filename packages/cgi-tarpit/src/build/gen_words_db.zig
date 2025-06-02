// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var arg_iter = try std.process.argsWithAllocator(arena);
    _ = arg_iter.skip();
    const input = arg_iter.next() orelse fatal("missing input file", .{});
    const output = arg_iter.next() orelse fatal("missing output file", .{});

    var input_file = try std.fs.cwd().openFile(input, .{});
    defer input_file.close();

    var output_file = try std.fs.cwd().createFile(output, .{});
    output_file.close();

    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = output },
        .open_flags = .{
            .write = true,
            .create = true,
        },
    });
    defer db.deinit();

    try db.exec("BEGIN TRANSACTION", .{}, .{});
    try db.exec("CREATE TABLE words(word TEXT PRIMARY KEY) WITHOUT ROWID, STRICT", .{}, .{});

    var stmt = try db.prepare("INSERT INTO words VALUES(?)");
    defer stmt.deinit();

    var line = std.ArrayList(u8).init(arena);
    while (input_file.reader().streamUntilDelimiter(line.writer(), '\n', null)) {
        defer line.clearRetainingCapacity();

        if (line.items.len < 1 or line.items[0] == '#') {
            continue;
        }

        var iter = std.mem.tokenizeAny(u8, line.items, " \t");
        _ = iter.next();
        const word = iter.rest();
        if (word.len < 1) {
            continue;
        }

        stmt.reset();
        try stmt.exec(.{}, .{word});
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    try db.exec("COMMIT", .{}, .{});
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format ++ "\n", args);
    std.process.exit(1);
}
