// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");

const T = 30000;
const tau = 5000;

pub fn conforming(src: []const u8, t_a: i64) !bool {
    var db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "gcra.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
    });
    defer db.deinit();

    try init(&db);
    defer deinit(&db);

    const TAT = blk: {
        var stmt = try db.prepare(
            \\SELECT tat from cells
            \\WHERE src = ?
        );
        defer stmt.deinit();

        break :blk (try stmt.one(i64, .{}, .{ .src = src })) orelse t_a;
    };

    if (t_a < TAT - tau) {
        return false;
    }

    var stmt = try db.prepare(
        \\INSERT INTO cells(src, tat)
        \\  VALUES($src, $tat)
        \\  ON CONFLICT(src) DO UPDATE SET
        \\      tat=excluded.tat
        \\  WHERE excluded.tat>cells.tat
    );
    defer stmt.deinit();

    try stmt.exec(.{}, .{ .src = src, .tat = @max(t_a, TAT) + T });

    return true;
}

fn init(db: *sqlite.Db) !void {
    _ = try db.pragma(void, .{}, "busy_timeout", "5000");
    _ = try db.pragma(void, .{}, "journal_mode", "wal");
    _ = try db.pragma(void, .{}, "synchronous", "normal");

    try db.exec(
        \\CREATE TABLE IF NOT EXISTS cells(
        \\  src TEXT PRIMARY KEY,
        \\  tat INTEGER DEFAULT 0
        \\)
        \\WITHOUT ROWID,
        \\STRICT
    ,
        .{},
        .{},
    );
}

fn deinit(db: *sqlite.Db) void {
    _ = db.pragma(void, .{}, "analysis_limit", "400") catch |err| std.log.err("failed to 'PRAGMA analysis_limit=400': {}", .{err});
    _ = db.pragma(void, .{}, "optimize", null) catch |err| std.log.err("failed to 'PRAGMA optimize': {}", .{err});
}

pub const GCRA = struct {
    db: *sqlite.Db,

    pub fn init(db: *sqlite.Db) !GCRA {
        _ = try db.pragma(void, .{}, "busy_timeout", "5000");
        _ = try db.pragma(void, .{}, "journal_mode", "wal");
        _ = try db.pragma(void, .{}, "synchronous", "normal");

        try db.exec(
            \\CREATE TABLE IF NOT EXISTS cells(
            \\  src TEXT PRIMARY KEY,
            \\  tat INTEGER DEFAULT 0
            \\)
            \\WITHOUT ROWID,
            \\STRICT
        ,
            .{},
            .{},
        );

        return GCRA{ .db = db };
    }

    pub fn deinit(self: *GCRA) void {
        defer self.db.deinit();

        _ = self.db.pragma(void, .{}, "analysis_limit", "400") catch |err| std.log.err("failed to 'PRAGMA analysis_limit=400': {}", .{err});
        _ = self.db.pragma(void, .{}, "optimize", null) catch |err| std.log.err("failed to 'PRAGMA optimize': {}", .{err});
    }

    pub fn retryAfter(self: *GCRA, src: []const u8, t_a: i64) !?i64 {
        const TAT = blk: {
            var stmt = try self.db.prepare(
                \\SELECT tat from cells
                \\WHERE src = ?
            );
            defer stmt.deinit();

            break :blk (try stmt.one(i64, .{}, .{ .src = src })) orelse t_a;
        };

        if (t_a < TAT - tau) {
            return std.math.divCeil(i64, TAT - t_a, 1000) catch std.math.maxInt(i64);
        }

        var stmt = try self.db.prepare(
            \\INSERT INTO cells(src, tat)
            \\  VALUES($src, $tat)
            \\  ON CONFLICT(src) DO UPDATE SET
            \\      tat=excluded.tat
            \\  WHERE excluded.tat>cells.tat
        );
        defer stmt.deinit();

        try stmt.exec(.{}, .{ .src = src, .tat = @max(t_a, TAT) + T });
        return null;
    }
};
