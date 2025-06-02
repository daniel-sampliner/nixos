// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const sqlite = @import("sqlite");

pub fn init(db: *sqlite.Db) !void {
    _ = db.createScalarFunction("randoms", randoms, .{ .deterministic = false }) catch |err| {
        std.log.err("unable to create 'randoms' SQLite function: {!}", .{err});
        return err;
    };
}

var prng: std.Random.DefaultPrng = undefined;
var initial_seed: i64 = undefined;
var init_prng = std.once(struct {
    fn run() void {
        prng = std.Random.DefaultPrng.init(@bitCast(initial_seed));
    }
}.run);

fn randoms(seed: i64) i64 {
    initial_seed = seed;
    init_prng.call();

    const rand = prng.random();
    return rand.int(i64);
}

test "randoms" {
    var db = try sqlite.Db.init(.{});
    defer db.deinit();

    try init(&db);

    var test_prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const rand = test_prng.random();

    var stmt = try db.prepare("SELECT randoms(?)");
    defer stmt.deinit();

    var prev = try stmt.one(i64, .{}, .{std.testing.random_seed});
    try std.testing.expectEqual(rand.int(i64), prev);

    for (0..10) |_| {
        stmt.reset();
        const got = try stmt.one(i64, .{}, .{std.testing.random_seed});
        try std.testing.expectEqual(rand.int(i64), got);
        try std.testing.expect(got != prev);
        prev = got;
    }
}
