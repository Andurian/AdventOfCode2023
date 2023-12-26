const std = @import("std");

const Unit = struct {
    day_exe: *std.Build.Step.Compile,
    day_test: *std.Build.Step.Compile,
};

fn addDay(b: *std.Build, name: []const u8, path: []const u8, util: *std.Build.Module, optimize: std.builtin.Mode) Unit {
    const day_exe = b.addExecutable(.{ .name = name, .root_source_file = .{ .path = path }, .optimize = optimize });
    day_exe.addModule("util", util);
    b.installArtifact(day_exe);

    const day_test = b.addTest(.{ .root_source_file = .{ .path = path } });
    day_test.addModule("util", util);

    return .{ .day_exe = day_exe, .day_test = day_test };
}

fn makeCurrent(b: *std.Build, day: Unit) void {
    const run_tests = b.addRunArtifact(day.day_test);
    b.step("test", "Run Tests").dependOn(&run_tests.step);

    const run = b.addRunArtifact(day.day_exe);
    if (b.args) |args| {
        run.addArgs(args);
    }

    b.step("run", "Run the current day").dependOn(&run.step);
}

pub fn build(b: *std.Build) void {
    const optimizeMode = std.builtin.OptimizeMode.ReleaseFast;
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = optimizeMode });

    const util = b.createModule(.{ .source_file = .{ .path = "src/util/util.zig" } });

    _ = addDay(b, "Day_01", "src/day_01/day_01.zig", util, optimize);
    _ = addDay(b, "Day_02", "src/day_02/day_02.zig", util, optimize);
    _ = addDay(b, "Day_03", "src/day_03/day_03.zig", util, optimize);
    _ = addDay(b, "Day_04", "src/day_04/day_04.zig", util, optimize);
    _ = addDay(b, "Day_05", "src/day_05/day_05.zig", util, optimize);
    _ = addDay(b, "Day_06", "src/day_06/day_06.zig", util, optimize);
    _ = addDay(b, "Day_07", "src/day_07/day_07.zig", util, optimize);
    _ = addDay(b, "Day_08", "src/day_08/day_08.zig", util, optimize);
    _ = addDay(b, "Day_09", "src/day_09/day_09.zig", util, optimize);
    _ = addDay(b, "Day_10", "src/day_10/day_10.zig", util, optimize);
    _ = addDay(b, "Day_11", "src/day_11/day_11.zig", util, optimize);
    _ = addDay(b, "Day_12", "src/day_12/day_12.zig", util, optimize);
    _ = addDay(b, "Day_13", "src/day_13/day_13.zig", util, optimize);
    _ = addDay(b, "Day_14", "src/day_14/day_14.zig", util, optimize);
    _ = addDay(b, "Day_15", "src/day_15/day_15.zig", util, optimize);
    _ = addDay(b, "Day_16", "src/day_16/day_16.zig", util, optimize);
    _ = addDay(b, "Day_17", "src/day_17/day_17.zig", util, optimize);
    _ = addDay(b, "Day_18", "src/day_18/day_18.zig", util, optimize);
    _ = addDay(b, "Day_19", "src/day_19/day_19.zig", util, optimize);
    _ = addDay(b, "Day_20", "src/day_20/day_20.zig", util, optimize);
    makeCurrent(b, addDay(b, "Day_21", "src/day_21/day_21.zig", util, optimize));
    _ = addDay(b, "Day_22", "src/day_22/day_22.zig", util, optimize);
    _ = addDay(b, "Day_23", "src/day_23/day_23.zig", util, optimize);
    _ = addDay(b, "Day_24", "src/day_24/day_24.zig", util, optimize);
    _ = addDay(b, "Day_25", "src/day_25/day_25.zig", util, optimize);

    const main = b.addExecutable(.{ .name = "AdventOfCode_2023", .root_source_file = .{ .path = "src/main.zig" } });
    main.addModule("util", util);
    b.installArtifact(main);
}
