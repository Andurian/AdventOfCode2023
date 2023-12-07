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
    const optimizeMode = std.builtin.OptimizeMode.Debug;
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = optimizeMode });

    const util = b.createModule(.{ .source_file = .{ .path = "src/util/util.zig" } });

    _ = addDay(b, "Day_01", "src/day_01/day_01.zig", util, optimize);
    _ = addDay(b, "Day_02", "src/day_02/day_02.zig", util, optimize);
    _ = addDay(b, "Day_03", "src/day_03/day_03.zig", util, optimize);
    _ = addDay(b, "Day_04", "src/day_04/day_04.zig", util, optimize);
    _ = addDay(b, "Day_05", "src/day_05/day_05.zig", util, optimize);
    _ = addDay(b, "Day_06", "src/day_06/day_06.zig", util, optimize);
    makeCurrent(b, addDay(b, "Day_07", "src/day_07/day_07.zig", util, optimize));

    const main = b.addExecutable(.{ .name = "AdventOfCode_2023", .root_source_file = .{ .path = "src/main.zig" } });
    main.addModule("util", util);
    b.installArtifact(main);
}
