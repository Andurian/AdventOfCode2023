const std = @import("std");
const util = @import("util");

const Head = @import("Head.zig");
const Tile = @import("tile.zig").Tile;
const Beam = @import("Beam.zig");

pub fn charFromBool(b: bool) u8 {
    if (b) return '#';
    return '.';
}

pub fn charFromOcc(b: [4]bool) u8 {
    var acc: i32 = 0;
    var c: u8 = '.';
    for (b, 0..) |bb, i| {
        if (bb) {
            acc += 1;
            c = @as(util.Direction, @enumFromInt(i)).toChar();
        }
    }
    if (acc == 0) return '.';
    if (acc == 1) return c;
    if (acc == 2) return '2';
    if (acc == 3) return '3';
    if (acc == 4) return '4';
    unreachable;
}

pub fn energizedFields(start: Head, field: util.Field(Tile), allocator: std.mem.Allocator) i32 {
    var beam = Beam.init(start, field, allocator);
    defer beam.deinit();

    beam.advanceAll(field);
    return beam.energizedFields();
}

pub fn task_01(field: util.Field(Tile), allocator: std.mem.Allocator) i32 {
    const start = Head{ .pos = .{ .row = 0, .col = 0 }, .orientation = util.Direction.East };
    return energizedFields(start, field, allocator);
}

pub fn task_02(field: util.Field(Tile), allocator: std.mem.Allocator) i32 {
    var maxEnergizedField: i32 = 0;

    var row: i32 = 0;
    while (row < field.height) : (row += 1) {
        maxEnergizedField = @max(maxEnergizedField, energizedFields(.{ .pos = .{ .row = row, .col = 0 }, .orientation = util.Direction.East }, field, allocator));
        maxEnergizedField = @max(maxEnergizedField, energizedFields(.{ .pos = .{ .row = row, .col = field.width - 1 }, .orientation = util.Direction.West }, field, allocator));
    }

    var col: i32 = 0;
    while (col < field.width) : (col += 1) {
        maxEnergizedField = @max(maxEnergizedField, energizedFields(.{ .pos = .{ .row = 0, .col = col }, .orientation = util.Direction.South }, field, allocator));
        maxEnergizedField = @max(maxEnergizedField, energizedFields(.{ .pos = .{ .row = field.height - 1, .col = col }, .orientation = util.Direction.North }, field, allocator));
    }

    return maxEnergizedField;
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

    var field = util.Field(Tile).initFromInput(input, Tile.make, allocator);
    defer field.deinit();

    std.debug.print("Day 16 Solution 1: {}\n", .{task_01(field, allocator)});
    std.debug.print("Day 16 Solution 2: {}\n", .{task_02(field, allocator)});
}
