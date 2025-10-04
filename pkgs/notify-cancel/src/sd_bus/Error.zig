// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const c = @import("c.zig");

const Error = @This();

const logger = @import("logger").logger(.@"sd_bus.Error");

sd_bus_error: *c.sd_bus_error,

pub fn free(e: *Error) void {
    _ = c.sd_bus_error_free(e.sd_bus_error);
}

pub fn format(
    e: Error,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    if (fmt.len == 0) {
        @branchHint(.cold);
        try writer.writeAll(@typeName(Error));
        try writer.writeAll("{");

        // if (e.sd_bus_error) |ee| {
        inline for (std.meta.fields(c.sd_bus_error), 0..) |f, i| {
            if (i == 0) {
                try writer.writeAll(" .");
            } else {
                try writer.writeAll(", .");
            }
            try writer.writeAll(f.name);
            try writer.writeAll(" = ");
            try std.fmt.formatType(
                @field(e.sd_bus_error, f.name),
                switch (f.type) {
                    ?[*:0]const u8 => "?s",
                    c_int => "d",
                    else => unreachable,
                },
                options,
                writer,
                std.fmt.default_max_depth - 1,
            );
        }
        // }
        try writer.writeAll(" }");
        return;
    }

    // if (e.sd_bus_error) |ee| {
    //     try writer.print("{?s}: {?s}", .{ ee.name, ee.message });
    // }
    try writer.print("{?s}: {?s}", .{ e.sd_bus_error.name, e.sd_bus_error.message });
}

test "format" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const e = Error{ .sd_bus_error = blk: {
        var ee = c.sd_bus_error{};
        ee.name = "NAME";
        ee.message = "MESSAGE";
        ee._need_free = -1;
        break :blk &ee;
    } };

    try std.testing.expectEqualStrings(
        "Error{ .name = NAME, .message = MESSAGE, ._need_free = -1 }",
        try std.fmt.allocPrint(allocator, "{any}", .{e}),
    );

    try std.testing.expectEqualStrings(
        "NAME: MESSAGE",
        try std.fmt.allocPrint(allocator, "{s}", .{e}),
    );
}

fn formatSdRetCode(
    value: c_int,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    const s = blk: {
        const E = std.posix.E;
        const e = std.meta.intToEnum(E, -value) catch break :blk "UNKNOWN";
        break :blk std.enums.tagName(E, e) orelse "UNKNOWN";
    };
    try std.fmt.formatType(s, fmt, options, writer, std.fmt.default_max_depth);
}

pub fn fmtSdRetCode(ret: c_int) std.fmt.Formatter(formatSdRetCode) {
    return .{ .data = ret };
}

test "fmtSdRetCode" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const TestCase = struct {
        ret: c_int,
        want: []const u8,
    };

    const tcs = [_]TestCase{
        .{ .ret = 0, .want = "SUCCESS" },
        .{ .ret = -1000, .want = "UNKNOWN" },
    };

    for (tcs) |tc| {
        const got = try std.fmt.allocPrint(allocator, "{s}", .{fmtSdRetCode(tc.ret)});
        try std.testing.expectEqualStrings(tc.want, got);
    }
}
