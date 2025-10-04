// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

const Debugger = enum {
    gdb,
    valgrind,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const logger_mod = b.createModule(.{
        .root_source_file = b.path("src/logger/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const sd_bus_mod = b.createModule(.{
        .root_source_file = b.path("src/sd_bus/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    sd_bus_mod.addImport("logger", logger_mod);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("logger", logger_mod);
    exe_mod.addImport("sd_bus", sd_bus_mod);

    const app_filter = b.option(
        []const u8,
        "app-filter",
        "App to filter notifications of",
    );
    const debugger = b.option(
        Debugger,
        "debugger",
        "debug tool to launch under",
    ) orelse null;
    const log_level = b.option(
        std.log.Level,
        "log-level",
        "Log level to use",
    );

    const options = b.addOptions();

    options.addOption([]const u8, "app_filter", app_filter orelse "Brave");
    options.addOption(bool, "use_debugger", if (debugger) |_| true else false);

    options.addOption(
        ?@typeInfo(std.log.Level).@"enum".tag_type,
        "log_level",
        if (log_level) |ll| @intFromEnum(ll) else null,
    );

    const options_mod = options.createModule();
    sd_bus_mod.addImport("config", options_mod);
    exe_mod.addImport("config", options_mod);

    const exe = b.addExecutable(.{
        .name = "notify_cancel",
        .root_module = exe_mod,
    });

    exe.linkSystemLibrary("libsystemd");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    const sd_bus_unit_tests = b.addTest(.{
        .name = "test_sd_bus",
        .root_module = sd_bus_mod,
        .target = target,
        .optimize = optimize,
        .filters = test_filters,
    });

    sd_bus_unit_tests.linkSystemLibrary("libsystemd");
    sd_bus_unit_tests.linkLibC();

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
        .target = target,
        .optimize = optimize,
        .filters = test_filters,
    });

    const run_sd_bus_unit_tests = b.addRunArtifact(sd_bus_unit_tests);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_sd_bus_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    if (debugger) |tool| {
        if (b.findProgram(&.{@tagName(tool)}, &.{})) |bin| {
            const args: []const []const u8 = switch (tool) {
                .gdb => &.{
                    bin,
                    "--tui",
                    "--eval-command=run",
                    "--",
                },

                .valgrind => &.{
                    bin,
                    "--leak-check=full",
                    "--track-origins=yes",
                    "--show-leak-kinds=all",
                    "--num-callers=15",
                    "--show-error-list=yes",
                    "--",
                },
            };

            for (args, 0..) |arg, i| {
                run_cmd.argv.insert(b.allocator, i, .{ .bytes = b.dupe(arg) }) catch @panic("OOM");
                run_sd_bus_unit_tests.argv.insert(b.allocator, i, .{ .bytes = b.dupe(arg) }) catch @panic("OOM");
                run_exe_unit_tests.argv.insert(b.allocator, i, .{ .bytes = b.dupe(arg) }) catch @panic("OOM");
            }
        } else |err| {
            const fail = b.addFail(b.fmt("{s}: {}", .{ @tagName(tool), err }));
            run_sd_bus_unit_tests.step.dependOn(&fail.step);
            run_exe_unit_tests.step.dependOn(&fail.step);
        }
    }

    const run_zig_fmt = b.addFmt(.{
        .paths = &.{b.build_root.path.?},
    });
    b.getInstallStep().dependOn(&run_zig_fmt.step);
    run_step.dependOn(&run_zig_fmt.step);
    test_step.dependOn(&run_zig_fmt.step);

    const fmt_step = b.step("fmt", "Format source code");
    fmt_step.dependOn(&run_zig_fmt.step);
}
