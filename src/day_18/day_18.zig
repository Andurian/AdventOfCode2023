const std = @import("std");
const util = @import("util");

const Task = enum { Task1, Task2 };

const Instruction = struct {
    direction: util.Direction,
    distance: i32,

    pub fn fromInput(str: []const u8, task: Task) Instruction {
        var it = std.mem.tokenize(u8, str, " (#)");
        const direction = it.next().?;
        const distance = it.next().?;
        const color = it.next().?;

        return switch (task) {
            .Task1 => fromStr(direction[0], distance),
            .Task2 => fromColor(color),
        };
    }

    pub fn fromStr(directionChar: u8, distanceStr: []const u8) Instruction {
        return .{ .direction = switch (directionChar) {
            'R' => .East,
            'U' => .North,
            'D' => .South,
            'L' => .West,
            else => unreachable,
        }, .distance = std.fmt.parseInt(i32, distanceStr, 10) catch unreachable };
    }

    pub fn fromColor(color: []const u8) Instruction {
        return .{ //
            .direction = switch (color[5]) {
                '0' => .East,
                '1' => .South,
                '2' => .West,
                '3' => .North,
                else => unreachable,
            }, //
            .distance = std.fmt.parseInt(i32, color[0..5], 16) catch unreachable,
        };
    }
};

const Polygon = struct {
    const Point = struct {
        pos: util.Point,
        dir1: util.Direction,
        dir2: util.Direction,
    };

    points: []Point,
    allocator: std.mem.Allocator,

    pub fn init(instructions: []const Instruction, allocator: std.mem.Allocator) Polygon {
        var points = allocator.alloc(Point, instructions.len) catch unreachable;

        var currentPos = util.Point{ .row = 0, .col = 0 };
        points[0] = .{
            .pos = currentPos,
            .dir1 = instructions[instructions.len - 1].direction,
            .dir2 = instructions[0].direction,
        };

        for (instructions, 0..) |instruction, i| {
            switch (instruction.direction) {
                .North => currentPos.row -= instruction.distance,
                .South => currentPos.row += instruction.distance,
                .West => currentPos.col -= instruction.distance,
                .East => currentPos.col += instruction.distance,
            }
            if (i != instructions.len - 1) {
                points[i + 1] = .{
                    .pos = currentPos,
                    .dir1 = instruction.direction,
                    .dir2 = instructions[i + 1].direction,
                };
            }
        }

        return .{ .points = points, .allocator = allocator };
    }

    pub fn deinit(self: *Polygon) void {
        self.allocator.free(self.points);
    }

    // Calculate area with the trapezoid formula
    // Can be simplified since every second product will be 0 when we only have vertical and horizontal
    // lines between points.
    pub fn area(self: Polygon) i128 {
        var acc: i64 = 0;
        for (self.points, 0..) |p1, i| {
            const p2 = if (i == self.points.len - 1) self.points[0] else self.points[i + 1];

            const r1: i128 = @intCast(p1.pos.row);
            const r2: i128 = @intCast(p2.pos.row);

            const c1: i128 = @intCast(p1.pos.col);
            const c2: i128 = @intCast(p2.pos.col);

            const v = (r1 + r2) * (c1 - c2);

            acc += v;
        }
        return @divTrunc(acc, 2);
    }

    // Expands the polygon by 0.5 units in each direction and shifts it by (0.5, 0.5) so that
    // we dont have to deal with floating point numbers.
    // Converts the area function from counting spaces between the coordinates to counting covered coordinates.
    pub fn expand(self: *Polygon) void {
        for (self.points) |*p| {
            switch (p.dir1) {
                .North => switch (p.dir2) {
                    .North => unreachable,
                    .East => {},
                    .South => unreachable,
                    .West => p.pos.row += 1,
                },
                .East => switch (p.dir2) {
                    .North => {},
                    .East => unreachable,
                    .South => p.pos.col += 1,
                    .West => unreachable,
                },
                .South => switch (p.dir2) {
                    .North => unreachable,
                    .East => p.pos.col += 1,
                    .South => unreachable,
                    .West => {
                        p.pos.row += 1;
                        p.pos.col += 1;
                    },
                },
                .West => switch (p.dir2) {
                    .North => p.pos.row += 1,
                    .East => unreachable,
                    .South => {
                        p.pos.row += 1;
                        p.pos.col += 1;
                    },
                    .West => unreachable,
                },
            }
        }
    }
};

pub fn parseInput(input: [][]const u8, task: Task, allocator: std.mem.Allocator) []Instruction {
    var arr = std.ArrayList(Instruction).init(allocator);
    defer arr.deinit();

    for (input) |line| {
        arr.append(Instruction.fromInput(line, task)) catch unreachable;
    }

    return arr.toOwnedSlice() catch unreachable;
}

pub fn solve(input: [][]const u8, task: Task, allocator: std.mem.Allocator) i128 {
    var instructions = parseInput(input, task, allocator);
    defer allocator.free(instructions);

    var poly = Polygon.init(instructions, allocator);
    defer poly.deinit();

    poly.expand();
    return poly.area();
}

pub fn task_01(input: [][]const u8, allocator: std.mem.Allocator) i128 {
    return solve(input, .Task1, allocator);
}

pub fn task_02(input: [][]const u8, allocator: std.mem.Allocator) i128 {
    return solve(input, .Task2, allocator);
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

    std.debug.print("Day 18 Solution 1: {}\n", .{task_01(input, allocator)});
    std.debug.print("Day 18 Solution 2: {}\n", .{task_02(input, allocator)});
}
