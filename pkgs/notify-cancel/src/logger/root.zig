// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const builtin = @import("builtin");
const std = @import("std");

pub fn logger(comptime scope: @Type(.enum_literal)) type {
    const l = std.log.scoped(scope);
    return switch (builtin.is_test) {
        false => l,
        true => struct {
            pub fn err(comptime format: []const u8, args: anytype) void {
                l.warn(format, args);
            }
            pub fn warn(comptime format: []const u8, args: anytype) void {
                l.warn(format, args);
            }
            pub fn info(comptime format: []const u8, args: anytype) void {
                l.info(format, args);
            }
            pub fn debug(comptime format: []const u8, args: anytype) void {
                l.debug(format, args);
            }
        },
    };
}
