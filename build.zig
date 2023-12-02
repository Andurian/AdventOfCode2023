const std = @import("std");

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

    const run_tests = b.addRunArtifact(day_02_test);
    b.step("test", "Run Tests").dependOn(&run_tests.step);

    const run = b.addRunArtifact(day_02);
    if (b.args) |args| {
        run.addArgs(args);
    }

    b.step("runall", "Run all days after each other").dependOn(&run.step);
}
