// SPDX-FileCopyrightText: 2025 Daniel Sampliner <samplinerD@gmail.com>
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const sqlite_dep = b.dependency("sqlite", .{
        .target = target,
        .optimize = optimize,
    });

    const gen_words_mod = b.createModule(.{
        .root_source_file = b.path("src/build/gen_words_db.zig"),
        .target = b.graph.host,
    });

    gen_words_mod.addImport("sqlite", sqlite_dep.module("sqlite"));

    const gen_words_exe = b.addExecutable(.{
        .name = "gen_words_db",
        .root_module = gen_words_mod,
    });

    const gen_words_step = b.addRunArtifact(gen_words_exe);
    gen_words_step.addFileArg(b.path("src/build/eff_large_wordlist.txt"));
    const words_db_path = gen_words_step.addOutputFileArg("words.db");
    const words_db_install_file = b.addInstallFile(words_db_path, "share/cgi_tarpit/words.db");
    b.getInstallStep().dependOn(&words_db_install_file.step);

    const options = b.addOptions();
    const words_db_option_path = try std.mem.concatWithSentinel(
        b.allocator,
        u8,
        &.{b.pathJoin(&.{ b.install_prefix, words_db_install_file.dest_rel_path })},
        0,
    );
    defer b.allocator.free(words_db_option_path);

    options.addOption([:0]const u8, "words_db", words_db_option_path);
    options.step.dependOn(&words_db_install_file.step);
    options.addOption(u32, "initial_write_bytes", b.option(u32, "initial_write_bytes", "initial bytes to write before throttling") orelse 1024);
    options.addOption(bool, "throttle", b.option(bool, "throttle", "throttle output") orelse true);

    const ZipBombMode = enum {
        yes,
        no,
        always,
    };

    options.addOption(ZipBombMode, "zipbomb", b.option(ZipBombMode, "zipbomb", "zipbomb after response limit exceeded") orelse .yes);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("sqlite", sqlite_dep.module("sqlite"));
    exe_mod.addOptions("config", options);

    const exe = b.addExecutable(.{
        .name = "cgi_tarpit",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const train_mod = b.createModule(.{
        .root_source_file = b.path("src/train.zig"),
        .target = target,
        .optimize = optimize,
    });

    train_mod.addImport("sqlite", sqlite_dep.module("sqlite"));

    const train = b.addExecutable(.{
        .name = "train",
        .root_module = train_mod,
    });

    b.installArtifact(train);
    const train_cmd = b.addRunArtifact(train);
    const train_step = b.step("train", "train on corpus");
    train_step.dependOn(&train_cmd.step);

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    const test_log_level = b.option(
        std.log.Level,
        "test-log-level",
        "Log level to use within tests",
    ) orelse std.testing.log_level;

    const test_options = b.addOptions();
    test_options.addOption(std.log.Level, "test_log_level", test_log_level);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
        .filters = test_filters,
    });

    exe_mod.addOptions("test_config", test_options);
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const train_unit_tests = b.addTest(.{
        .root_module = train_mod,
        .filters = test_filters,
    });

    train_mod.addOptions("test_config", test_options);
    const run_train_unit_tests = b.addRunArtifact(train_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_train_unit_tests.step);

    const clean_step = b.step("clean", "Clean up");
    clean_step.dependOn(&b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step);
}
