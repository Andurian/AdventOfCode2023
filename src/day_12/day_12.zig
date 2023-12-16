const std = @import("std");
const util = @import("util");

const Reading = @import("Reading.zig");
const Solver = @import("Solver.zig");

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Reading {
    var readings = allocator.alloc(Reading, input.len) catch unreachable;

    for (input, 0..) |line, i| {
        var reading = Reading.fromLine(line, allocator);
        readings[i] = reading;
    }

    return readings;
}

pub fn task_01(readings: []const Reading, allocator: std.mem.Allocator) u64 {
    var acc: u64 = 0;
    for (readings) |*r| {
        var solver = Solver.init(r, allocator);
        defer solver.deinit();

        acc += solver.solve();
    }
    return acc;
}

pub fn task_01_slow(readings: []const Reading) u64 {
    var acc: u64 = 0;
    for (readings) |r| {
        acc += r.generatePossibilities();
    }
    return acc;
}

pub fn task_02(readings: []const Reading, allocator: std.mem.Allocator) u64 {
    var acc: u64 = 0;
    for (readings) |r| {
        var r2 = r.expand();
        defer r2.deinit();

        var solver = Solver.init(&r2, allocator);
        defer solver.deinit();

        acc += solver.solve();
    }
    return acc;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile(args[1], allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var readings = parseInput(input, allocator);
    defer allocator.free(readings);
    defer for (readings) |*r| r.deinit();

    util.print("Day 12 Solution 1: {}\n", .{task_01(readings, allocator)});
    util.print("Day 12 Solution 1: {}\n", .{task_01_slow(readings)});
    util.print("Day 12 Solution 2: {}\n", .{task_02(readings, allocator)});
}
