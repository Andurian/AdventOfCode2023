const std = @import("std");

fn addDay(b: *std.Build, name: []const u8, path: []const u8, util: *std.Build.Module) void {
    _ = util;
    _ = path;
    _ = name;
    _ = b;
}

pub fn build(b: *std.Build) void {
    const util = b.createModule(.{ .source_file = .{ .path = "src/util/util.zig" } });

    const main = b.addExecutable(.{ .name = "AdventOfCode_2023", .root_source_file = .{ .path = "src/main.zig" } });
    main.addModule("util", util);
    b.installArtifact(main);

    const day_01 = b.addExecutable(.{ .name = "Day_01", .root_source_file = .{ .path = "src/day_01/day_01.zig" } });
    day_01.addModule("util", util);
    b.installArtifact(day_01);

    const day_02 = b.addExecutable(.{ .name = "Day_02", .root_source_file = .{ .path = "src/day_02/day_02.zig" } });
    day_02.addModule("util", util);
    b.installArtifact(day_02);

    const day_02_test = b.addTest(.{ .root_source_file = .{ .path = "src/day_02/day_02.zig" } });
    day_02_test.addModule("util", util);

    const day_03 = b.addExecutable(.{ .name = "Day_03", .root_source_file = .{ .path = "src/day_03/day_03.zig" } });
    day_03.addModule("util", util);
    b.installArtifact(day_03);

    const day_03_test = b.addTest(.{ .root_source_file = .{ .path = "src/day_03/day_03.zig" } });
    day_03_test.addModule("util", util);

    const day_04 = b.addExecutable(.{ .name = "Day_04", .root_source_file = .{ .path = "src/day_04/day_04.zig" } });
    day_04.addModule("util", util);
    b.installArtifact(day_04);

    const day_04_test = b.addTest(.{ .root_source_file = .{ .path = "src/day_04/day_04.zig" } });
    day_04_test.addModule("util", util);

    const run_tests = b.addRunArtifact(day_04_test);
    b.step("test", "Run Tests").dependOn(&run_tests.step);

    const run = b.addRunArtifact(day_04);
    if (b.args) |args| {
        run.addArgs(args);
    }

    b.step("runall", "Run all days after each other").dependOn(&run.step);
}
