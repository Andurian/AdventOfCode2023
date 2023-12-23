const std = @import("std");
const util = @import("util");

const Range = struct {
    min: i32,
    max: i32,

    pub fn overlaps(lhs: Range, rhs: Range) bool {
        return !(lhs.min > rhs.max) and !(lhs.max < rhs.min);
    }

    pub fn move(self: *Range, amount: i32) void {
        self.min += amount;
        self.max += amount;
    }

    pub fn moveToMin(self: *Range, newMin: i32) void {
        const amount = self.min - newMin;
        self.move(-amount);
    }
};

const Brick = struct {
    x: Range,
    y: Range,
    z: Range,

    pub fn fromInput(line: []const u8) Brick {
        var it = std.mem.tokenize(u8, line, ",~");
        const xMin = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        const yMin = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        const zMin = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        const xMax = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        const yMax = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        const zMax = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        return .{ //
            .x = .{ .min = @min(xMin, xMax), .max = @max(xMin, xMax) },
            .y = .{ .min = @min(yMin, yMax), .max = @max(yMin, yMax) },
            .z = .{ .min = @min(zMin, zMax), .max = @max(zMin, zMax) },
        };
    }

    pub fn lt(_: void, lhs: Brick, rhs: Brick) bool {
        if (lhs.z.min != rhs.z.min) return lhs.z.min < rhs.z.min;
        if (lhs.z.max != rhs.z.max) return lhs.z.max < rhs.z.max;

        if (lhs.y.min != rhs.y.min) return lhs.y.min < rhs.y.min;
        if (lhs.y.max != rhs.y.max) return lhs.y.max < rhs.y.max;

        if (lhs.x.min != rhs.x.min) return lhs.x.min < rhs.x.min;
        if (lhs.x.max != rhs.x.max) return lhs.x.max < rhs.x.max;

        return false;
    }

    pub fn print(self: Brick) void {
        util.print("x: [{}, {}], y: [{}, {}], z: [{}, {}]\n", .{ self.x.min, self.x.max, self.y.min, self.y.max, self.z.min, self.z.max });
    }
};

pub fn applyGravity(bricks: []Brick) i32 {
    // Bricks are sorted by the z-location so a bricks falling can never be influenced by one further up the list
    // And apparently thats not true...
    // TODO: Instead of iterating the entire list and checking which overlapping brick is the closest one with a maximum z value lower than our z value
    // Iterate only a subset of bricks and stop at the first one that overlaps to improve the runtime
    var fallingBrickCounter: i32 = 0;
    for (bricks, 0..) |*currentBrick, i| {
        _ = i;
        var newMin: i32 = 1;
        for (bricks) |lowerBrick| {
            if (lowerBrick.z.max < currentBrick.z.min and lowerBrick.z.max + 1 > newMin and Range.overlaps(lowerBrick.x, currentBrick.x) and Range.overlaps(lowerBrick.y, currentBrick.y)) {
                newMin = lowerBrick.z.max + 1;
            }
        }
        if (currentBrick.z.min != newMin) {
            currentBrick.z.moveToMin(newMin);
            fallingBrickCounter += 1;
        }
    }

    std.mem.sort(Brick, bricks, {}, Brick.lt);
    return fallingBrickCounter;
}

pub fn doesGravityApply(bricks: []const Brick) bool {
    for (bricks, 0..) |*currentBrick, i| {
        _ = i;
        var newMin: i32 = 1;
        for (bricks) |lowerBrick| {
            if (lowerBrick.z.max < currentBrick.z.min and lowerBrick.z.max + 1 > newMin and Range.overlaps(lowerBrick.x, currentBrick.x) and Range.overlaps(lowerBrick.y, currentBrick.y)) {
                newMin = lowerBrick.z.max + 1;
            }
        }
        if (currentBrick.z.min != newMin) {
            return true;
        }
    }
    return false;
}

pub fn canRemoveFrom(bricks: []const Brick, i: usize, allocator: std.mem.Allocator) bool {
    var bricksWithIRemoved = std.ArrayList(Brick).init(allocator);
    defer bricksWithIRemoved.deinit();

    bricksWithIRemoved.appendSlice(bricks[0..i]) catch unreachable;
    bricksWithIRemoved.appendSlice(bricks[i + 1 ..]) catch unreachable;

    return !doesGravityApply(bricksWithIRemoved.items);
}

pub fn numFallingBricksIfRemoved(bricks: []const Brick, i: usize, allocator: std.mem.Allocator) i32 {
    var bricksWithIRemoved = std.ArrayList(Brick).init(allocator);
    defer bricksWithIRemoved.deinit();

    bricksWithIRemoved.appendSlice(bricks[0..i]) catch unreachable;
    bricksWithIRemoved.appendSlice(bricks[i + 1 ..]) catch unreachable;

    return applyGravity(bricksWithIRemoved.items);
}

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Brick {
    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();

    for (input) |line| {
        bricks.append(Brick.fromInput(line)) catch unreachable;
    }

    std.mem.sort(Brick, bricks.items, {}, Brick.lt);

    return bricks.toOwnedSlice() catch unreachable;
}

pub fn task_01(bricks: []Brick, allocator: std.mem.Allocator) u64 {
    var acc: u64 = 0;
    var i: usize = 0;
    while (i < bricks.len) : (i += 1) {
        if (canRemoveFrom(bricks, i, allocator)) {
            acc += 1;
        }
    }

    return acc;
}

pub fn task_02(bricks: []Brick, allocator: std.mem.Allocator) i32 {
    var acc: i32 = 0;
    var i: usize = 0;
    while (i < bricks.len) : (i += 1) {
        acc += numFallingBricksIfRemoved(bricks, i, allocator);
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

    var bricks = parseInput(input, allocator);
    defer allocator.free(bricks);

    _ = applyGravity(bricks);

    util.print("Day 22 Solution 1: {}\n", .{task_01(bricks, allocator)});
    util.print("Day 22 Solution 2: {}\n", .{task_02(bricks, allocator)});
}
