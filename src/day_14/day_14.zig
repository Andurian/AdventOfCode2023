const std = @import("std");
const util = @import("util");

pub fn moveNorth(field: *util.Field(u8)) bool {
    var moved: bool = false;
    var row: i32 = 1;
    while (row < field.height) : (row += 1) {
        var col: i32 = 0;
        while (col < field.width) : (col += 1) {
            const p = util.Point{ .row = row, .col = col };
            const n = p.neighbor(util.Direction.North);

            if (field.at(p) catch unreachable == 'O' and field.at(n) catch unreachable == '.') {
                field.set(n, 'O');
                field.set(p, '.');
                moved = true;
            }
        }
    }
    return moved;
}

pub fn moveSouth(field: *util.Field(u8)) bool {
    var moved: bool = false;
    var row: i32 = field.height - 2;
    while (row >= 0) : (row -= 1) {
        var col: i32 = 0;
        while (col < field.width) : (col += 1) {
            const p = util.Point{ .row = row, .col = col };
            const n = p.neighbor(util.Direction.South);

            if (field.at(p) catch unreachable == 'O' and field.at(n) catch unreachable == '.') {
                field.set(n, 'O');
                field.set(p, '.');
                moved = true;
            }
        }
    }
    return moved;
}

pub fn moveWest(field: *util.Field(u8)) bool {
    var moved: bool = false;

    var col: i32 = 1;
    while (col < field.width) : (col += 1) {
        var row: i32 = 0;
        while (row < field.height) : (row += 1) {
            const p = util.Point{ .row = row, .col = col };
            const n = p.neighbor(util.Direction.West);

            if (field.at(p) catch unreachable == 'O' and field.at(n) catch unreachable == '.') {
                field.set(n, 'O');
                field.set(p, '.');
                moved = true;
            }
        }
    }
    return moved;
}

pub fn moveEast(field: *util.Field(u8)) bool {
    var moved: bool = false;

    var col: i32 = field.width - 2;
    while (col >= 0) : (col -= 1) {
        var row: i32 = 0;
        while (row < field.height) : (row += 1) {
            const p = util.Point{ .row = row, .col = col };
            const n = p.neighbor(util.Direction.East);

            if (field.at(p) catch unreachable == 'O' and field.at(n) catch unreachable == '.') {
                field.set(n, 'O');
                field.set(p, '.');
                moved = true;
            }
        }
    }
    return moved;
}

pub fn calcLoad(field: util.Field(u8)) i32 {
    var acc: i32 = 0;
    var row: i32 = 0;
    while (row < field.height) : (row += 1) {
        var col: i32 = 0;
        while (col < field.width) : (col += 1) {
            const p = util.Point{ .row = row, .col = col };
            if (field.at(p) catch unreachable == 'O') {
                acc += field.height - row;
            }
        }
    }

    return acc;
}

pub fn endsWithCycleOfLength(arr: []const i32, s: usize) bool {
    if (arr.len < 3 * s) return false;

    const s1 = arr[arr.len - s ..];
    const s2 = arr[arr.len - 2 * s .. arr.len - s];
    const s3 = arr[arr.len - 3 * s .. arr.len - 2 * s];

    // Assume we found a cycle if the array ends with a three times repeating sequence of length s

    return std.mem.eql(i32, s1, s2) and std.mem.eql(i32, s1, s3);
}

pub fn task_01(field: *util.Field(u8)) i32 {
    while (moveNorth(field)) {}
    return calcLoad(field.*);
}

pub fn task_02(field: *util.Field(u8)) i32 {
    var seenLoads = std.ArrayList(i32).init(field.allocator);
    defer seenLoads.deinit();

    var i: usize = 0;
    while (true) : (i += 1) {
        var n = calcLoad(field.*);
        seenLoads.append(n) catch unreachable;

        var j: usize = 2;
        while (j < 15) : (j += 1) {
            if (endsWithCycleOfLength(seenLoads.items, j)) {
                const ramp = i - 3 * j;
                const target: usize = 1000000000;
                const cycleOffset = (target - ramp) % j;
                const x = seenLoads.items[ramp + cycleOffset];
                return x;
            }
        }

        while (moveNorth(field)) {}
        while (moveWest(field)) {}
        while (moveSouth(field)) {}
        while (moveEast(field)) {}
    }

    unreachable;
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

    {
        var field = util.Field(u8).initFromInput(input, util.traits(u8).id, allocator);
        defer field.deinit();

        util.print("Day 14 Solution 1: {}\n", .{task_01(&field)});
    }

    {
        var field = util.Field(u8).initFromInput(input, util.traits(u8).id, allocator);
        defer field.deinit();

        util.print("Day 14 Solution 2: {}\n", .{task_02(&field)});
    }
}
