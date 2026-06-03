// SPDX-FileCopyrightText: 2025, 2026 Daniel Sampliner <samplinerD@gmail.com>
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

pub fn format(e: Error, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{?s}: {?s}", .{ e.sd_bus_error.name, e.sd_bus_error.message });
}

pub fn fmtVerbose(e: Error) std.fmt.Alt(Error, Error.formatVerbose) {
    return .{ .data = e };
}

fn formatVerbose(e: Error, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll(@typeName(Error));
    try writer.writeAll("{");

    inline for (std.meta.fields(c.sd_bus_error), 0..) |f, i| {
        if (i == 0) {
            try writer.writeAll(" .");
        } else {
            try writer.writeAll(", .");
        }
        try writer.writeAll(f.name);
        try writer.writeAll(" = ");
        try writer.printValue(
            switch (f.type) {
                ?[*:0]const u8 => "?s",
                c_int => "d",
                else => unreachable,
            },
            .{},
            @field(e.sd_bus_error, f.name),
            std.options.fmt_max_depth - 1,
        );
    }

    try writer.writeAll(" }");
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
        try std.fmt.allocPrint(allocator, "{f}", .{e.fmtVerbose()}),
    );

    try std.testing.expectEqualStrings(
        "NAME: MESSAGE",
        try std.fmt.allocPrint(allocator, "{f}", .{e}),
    );
}

pub fn fmtSdRetCode(rc: c_int) std.fmt.Alt(SdRetCode, SdRetCode.format) {
    return .{ .data = .{ .rc = rc } };
}

const SdRetCode = union {
    rc: c_int,

    pub fn format(sd: SdRetCode, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const s = blk: {
            const E = std.posix.E;
            const e = std.enums.fromInt(E, -sd.rc) orelse break :blk "UNKNOWN";
            break :blk std.enums.tagName(E, e) orelse "UNKNOWN";
        };
        try writer.print("{s}", .{s});
    }
};

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
        const got = try std.fmt.allocPrint(allocator, "{f}", .{fmtSdRetCode(tc.ret)});
        try std.testing.expectEqualStrings(tc.want, got);
    }
}
