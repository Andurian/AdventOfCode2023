const std = @import("std");
const util = @import("util");

const Tile = enum {
    Start,
    Rock,
    Plot,
    Elf,

    pub fn fromChar(c: u8) Tile {
        return switch (c) {
            'S' => .Start,
            '.' => .Plot,
            '#' => .Rock,
            'O' => .Elf,
            else => unreachable,
        };
    }

    pub fn toChar(t: Tile) u8 {
        return switch (t) {
            .Start => 'S',
            .Plot => '.',
            .Rock => '#',
            .Elf => 'O',
        };
    }
};

const PredicateParity = enum { Even, Odd };

const ElfWalker = struct {
    field: util.Field(Tile),
    start: util.Point,
    distances: util.Field(i32),
    allocator: std.mem.Allocator,

    fn findStart(field: util.Field(Tile)) util.Point {
        var it = field.positionIterator();
        while (it.next()) |p| {
            if (field.at(p) catch unreachable == .Start) return p;
        }
        unreachable;
    }

    fn findDistances(field: util.Field(Tile), start: util.Point, allocator: std.mem.Allocator) util.Field(i32) {
        var distances = util.Field(i32).initWithDefault(field.width, field.height, -1, allocator);
        distances.set(start, 0);

        var positions = std.ArrayList(util.Point).init(allocator);
        defer positions.deinit();

        var nextPositions = std.ArrayList(util.Point).init(allocator);
        defer nextPositions.deinit();

        positions.append(start) catch unreachable;

        var d: i32 = 1;
        while (positions.items.len > 0) {
            nextPositions.clearRetainingCapacity();

            for (positions.items) |p| {
                for (p.neighbors4()) |m| {
                    if (!field.contains(m)) continue;

                    const previousDistance = distances.at(m) catch unreachable;

                    if (field.at(m) catch unreachable != .Rock and (previousDistance == -1 or previousDistance > d)) {
                        distances.set(m, d);
                        nextPositions.append(m) catch unreachable;
                    }
                }
            }
            d += 1;

            positions.clearRetainingCapacity();
            positions.appendSlice(nextPositions.items) catch unreachable;
        }

        return distances;
    }

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) ElfWalker {
        var field = util.Field(Tile).initFromInput(input, Tile.fromChar, allocator);

        const start = findStart(field);

        return .{ .field = field, .start = start, .distances = findDistances(field, start, allocator), .allocator = allocator };
    }

    pub fn deinit(self: *ElfWalker) void {
        self.field.deinit();
        self.distances.deinit();
    }

    pub fn walk2(self: ElfWalker, numSteps: u64) u64 {
        var acc: u64 = 0;
        var it = self.distances.iterator();
        while (it.next()) |d| {
            if (d < 0) continue;
            const du = @as(u64, @intCast(d));
            if (du % 2 == numSteps % 2 and du <= numSteps) acc += 1;
        }
        return acc;
    }

    pub fn countEven(self: ElfWalker, limit: ?u64) u64 {
        var acc: u64 = 0;
        var it = self.distances.iterator();
        while (it.next()) |d| {
            if (d < 0) continue;
            const du = @as(u64, @intCast(d));

            if (du % 2 == 1) continue;

            if (limit) |x| {
                if (du > x) {
                    acc += 1;
                }
            } else {
                acc += 1;
            }
        }
        return acc;
    }

    pub fn countOdd(self: ElfWalker, limit: ?u64) u64 {
        var acc: u64 = 0;
        var it = self.distances.iterator();
        while (it.next()) |d| {
            if (d < 0) continue;
            const du = @as(u64, @intCast(d));

            if (du % 2 == 0) continue;

            if (limit) |x| {
                if (du > x) {
                    acc += 1;
                }
            } else {
                acc += 1;
            }
        }
        return acc;
    }

    pub fn walk(self: ElfWalker, numSteps: u64) u64 {
        var positions = std.ArrayList(util.Point).init(self.allocator);
        defer positions.deinit();

        var nextPositions = std.ArrayList(util.Point).init(self.allocator);
        defer nextPositions.deinit();

        positions.append(self.start) catch unreachable;

        var i: u64 = 0;
        while (i < numSteps) : (i += 1) {
            nextPositions.clearRetainingCapacity();

            for (positions.items) |p| {
                for (p.neighbors4()) |m| {
                    var n = m;
                    while (n.row < 0) : (n.row += self.field.height) {}
                    while (n.col < 0) : (n.col += self.field.width) {}
                    while (n.row >= self.field.height) : (n.row -= self.field.height) {}
                    while (n.col >= self.field.width) : (n.col -= self.field.width) {}

                    if (self.field.at(n) catch unreachable != .Rock and !util.contains(util.Point, nextPositions, m)) {
                        nextPositions.append(m) catch unreachable;
                    }
                }
            }

            positions.clearRetainingCapacity();
            positions.appendSlice(nextPositions.items) catch unreachable;

            // Just printing Stuff
            // if (i % 10 == 0) {
            //     var f2 = self.field.clone();
            //     defer f2.deinit();

            //     for (positions.items) |p| {
            //         var n = p;
            //         while (n.row < 0) : (n.row += self.field.height) {}
            //         while (n.col < 0) : (n.col += self.field.width) {}
            //         while (n.row >= self.field.height) : (n.row -= self.field.height) {}
            //         while (n.col >= self.field.width) : (n.col -= self.field.width) {}
            //         f2.set(n, .Elf);
            //     }

            //     util.print("{}:\n", .{i});
            //     f2.print(Tile.toChar);

            //     util.print("---\n", .{});
            // }
        }

        return positions.items.len;
    }
};

pub fn task_01(walker: ElfWalker) u64 {
    return walker.walk2(64);
}

pub fn task_02(walker: ElfWalker) u64 {
    const allEven = walker.countEven(null);
    const allOdd = walker.countOdd(null);
    const cornerEven = walker.countEven(65);
    const cornerOdd = walker.countOdd(65);

    const n: u64 = 202300;

    return (n + 1) * (n + 1) * allOdd + n * n * allEven - (n + 1) * cornerOdd + n * cornerEven;
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

    var walker = ElfWalker.initFromInput(input, allocator);
    defer walker.deinit();

    util.print("Day 21 Solution 1: {}\n", .{task_01(walker)});
    util.print("Day 21 Solution 2: {}\n", .{task_02(walker)});
}
