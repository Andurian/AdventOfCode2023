const std = @import("std");
const util = @import("util");

const Direction = enum(u8) { North, East, South, West };

pub fn lt_direction(_: void, lhs: Direction, rhs: Direction) bool {
    return @intFromEnum(lhs) < @intFromEnum(rhs);
}

pub fn silence(t: anytype) void {
    _ = t;
}

const Point = struct {
    row: i32,
    col: i32,

    pub fn neighbors8(self: Point) [8]Point {
        return [8]Point{ //
            .{ .row = self.row - 1, .col = self.col - 1 }, //
            .{ .row = self.row - 1, .col = self.col + 0 }, //
            .{ .row = self.row - 1, .col = self.col + 1 }, //
            .{ .row = self.row + 0, .col = self.col - 1 }, //
            .{ .row = self.row + 0, .col = self.col + 1 }, //
            .{ .row = self.row + 1, .col = self.col - 1 }, //
            .{ .row = self.row + 1, .col = self.col + 0 }, //
            .{ .row = self.row + 1, .col = self.col + 1 }, //
        };
    }

    pub fn neighbors4(self: Point) [4]Point {
        return [4]Point{ //
            .{ .row = self.row - 1, .col = self.col + 0 }, //
            .{ .row = self.row + 0, .col = self.col - 1 }, //
            .{ .row = self.row + 0, .col = self.col + 1 }, //
            .{ .row = self.row + 1, .col = self.col + 0 }, //
        };
    }

    pub fn neighbor(self: Point, direction: Direction) Point {
        return switch (direction) {
            Direction.North => .{ .row = self.row - 1, .col = self.col }, //
            Direction.South => .{ .row = self.row + 1, .col = self.col }, //
            Direction.West => .{ .row = self.row, .col = self.col - 1 }, //
            Direction.East => .{ .row = self.row, .col = self.col + 1 }, //
        };
    }
};

const Tile = enum(u8) {
    Empty,
    EmptyIn,
    NorthSouth,
    WestEast,
    NorthWest,
    NorthEast,
    SouthWest,
    SouthEast,
    Start,

    pub fn fromChar(c: u8) Tile {
        switch (c) {
            '.' => return Tile.Empty,
            '|' => return Tile.NorthSouth,
            '-' => return Tile.WestEast,
            'L' => return Tile.NorthEast,
            'J' => return Tile.NorthWest,
            '7' => return Tile.SouthWest,
            'F' => return Tile.SouthEast,
            'S' => return Tile.Start,
            else => unreachable,
        }
    }

    pub fn toChar(t: Tile) u21 {
        return switch (t) {
            Tile.Empty => ' ',
            Tile.EmptyIn => 'I',
            Tile.NorthSouth => '│',
            Tile.WestEast => '─',
            Tile.NorthEast => '└',
            Tile.NorthWest => '┘',
            Tile.SouthEast => '┌',
            Tile.SouthWest => '┐',
            Tile.Start => '#',
        };
    }

    pub fn connections(t: Tile) ![2]Direction {
        return switch (t) {
            Tile.Empty => error.InvalidTile,
            Tile.EmptyIn => error.InvalidTile,
            Tile.NorthSouth => [2]Direction{ Direction.North, Direction.South },
            Tile.WestEast => [2]Direction{ Direction.West, Direction.East },
            Tile.NorthEast => [2]Direction{ Direction.North, Direction.East },
            Tile.NorthWest => [2]Direction{ Direction.North, Direction.West },
            Tile.SouthEast => [2]Direction{ Direction.South, Direction.East },
            Tile.SouthWest => [2]Direction{ Direction.South, Direction.West },
            Tile.Start => error.InvalidTile,
        };
    }
};

const Field = struct {
    width: i32,
    height: i32,
    start: Point,
    data: []Tile,
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) Field {
        const height = input.len;
        const width = input[0].len;
        const s: usize = width * height;
        var data = allocator.alloc(Tile, s) catch unreachable;

        var start = Point{ .row = -1, .col = -1 };

        var row: usize = 0;
        while (row < height) : (row += 1) {
            var col: usize = 0;
            while (col < width) : (col += 1) {
                const i = row * width + col;
                data[i] = Tile.fromChar(input[row][col]);
                if (data[i] == Tile.Start) {
                    start = Point{ .col = @intCast(col), .row = @intCast(row) };
                }
            }
        }

        return Field{
            .width = @intCast(width), //
            .height = @intCast(height), //
            .data = data, //
            .start = start, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Field) void {
        self.allocator.free(self.data);
    }

    pub fn contains(self: Field, point: Point) bool {
        return point.row >= 0 and point.row < self.height and point.col >= 0 and point.col < self.width;
    }

    pub fn at(self: Field, point: Point) !Tile {
        if (!self.contains(point)) {
            return error.OutOfFiledAccess;
        }
        const pos: usize = @intCast(point.row * self.width + point.col);
        return self.data[pos];
    }

    pub fn fixStart(self: *Field) void {
        var startConnections = std.ArrayList(Direction).init(self.allocator);
        defer startConnections.deinit();

        const nNorth = self.start.neighbor(Direction.North);
        const nSouth = self.start.neighbor(Direction.South);
        const nEast = self.start.neighbor(Direction.East);
        const nWest = self.start.neighbor(Direction.West);

        if (self.contains(nNorth)) {
            const tNorth = self.at(nNorth) catch unreachable;
            const conn = tNorth.connections();

            if (conn) |c| {
                if (util.contains_(Direction, &c, Direction.South)) {
                    startConnections.append(Direction.North) catch unreachable;
                }
            } else |err| {
                err catch {};
            }
        }

        if (self.contains(nEast)) {
            const tEast = self.at(nEast) catch unreachable;
            const conn = tEast.connections();

            if (conn) |c| {
                if (util.contains_(Direction, &c, Direction.West)) {
                    startConnections.append(Direction.East) catch unreachable;
                }
            } else |err| {
                err catch {};
            }
        }

        if (self.contains(nSouth)) {
            const tSouth = self.at(nSouth) catch unreachable;
            const conn = tSouth.connections();

            if (conn) |c| {
                if (util.contains_(Direction, &c, Direction.North)) {
                    startConnections.append(Direction.South) catch unreachable;
                }
            } else |err| {
                err catch {};
            }
        }

        if (self.contains(nWest)) {
            const tWest = self.at(nWest) catch unreachable;
            const conn = tWest.connections();

            if (conn) |c| {
                if (util.contains_(Direction, &c, Direction.East)) {
                    startConnections.append(Direction.West) catch unreachable;
                }
            } else |err| {
                err catch {};
            }
        }

        for (startConnections.items) |it| {
            util.print("{s}\n", .{@tagName(it)});
        }

        std.mem.sort(Direction, startConnections.items, {}, lt_direction);
        const i: usize = @intCast(self.start.row * self.width + self.start.col);

        if (startConnections.items[0] == Direction.North) {
            if (startConnections.items[1] == Direction.East) {
                self.data[i] = Tile.NorthEast;
            }
            if (startConnections.items[1] == Direction.South) {
                self.data[i] = Tile.NorthSouth;
            }
            if (startConnections.items[1] == Direction.West) {
                self.data[i] = Tile.NorthWest;
            }
        }

        if (startConnections.items[0] == Direction.East) {
            if (startConnections.items[1] == Direction.South) {
                self.data[i] = Tile.SouthEast;
            }
            if (startConnections.items[1] == Direction.West) {
                self.data[i] = Tile.WestEast;
            }
        }

        if (startConnections.items[0] == Direction.South) {
            if (startConnections.items[1] == Direction.West) {
                self.data[i] = Tile.SouthWest;
            }
        }
    }

    pub fn findLoop(self: Field) []Point {
        var steps = std.ArrayList(Point).init(self.allocator);
        defer steps.deinit();

        steps.append(self.start) catch unreachable;

        var current = self.start;
        var previous: Point = undefined;

        while (!std.meta.eql(current, self.start) or steps.items.len <= 1) {
            const currentTile = self.at(current) catch unreachable;
            var nextDirs = currentTile.connections() catch unreachable;
            var nextDir: Direction = undefined;

            if (std.meta.eql(current, self.start)) {
                nextDir = nextDirs[0];
            } else {
                const potentialNext = current.neighbor(nextDirs[0]);
                if (std.meta.eql(previous, potentialNext)) {
                    nextDir = nextDirs[1];
                } else {
                    nextDir = nextDirs[0];
                }
            }

            const next = current.neighbor(nextDir);

            previous = current;
            current = next;

            steps.append(current) catch unreachable;
        }

        return steps.toOwnedSlice() catch unreachable;
    }

    pub fn cleanLoop(self: *Field) void {
        var loop = self.findLoop();
        defer self.allocator.free(loop);

        var row: i32 = 0;
        while (row < self.height) : (row += 1) {
            var col: i32 = 0;
            while (col < self.width) : (col += 1) {
                const p = Point{ .row = row, .col = col };
                if (!util.contains_(Point, loop, p)) {
                    const i: usize = @intCast(row * self.width + col);
                    self.data[i] = Tile.Empty;
                }
            }
        }
    }

    pub fn findInside(self: *Field) i32 {
        var acc: i32 = 0;

        var row: i32 = 0;
        while (row < self.height) : (row += 1) {
            var col: i32 = 0;
            var in: bool = false;
            var onHorizontalEdge: bool = false;
            var horizontalEdgeStart: Tile = undefined;
            while (col < self.width) : (col += 1) {
                const p = Point{ .row = row, .col = col };
                const i: usize = @intCast(row * self.width + col);
                const t = self.at(p) catch unreachable;

                if (t == Tile.Empty) {
                    if (in) {
                        self.data[i] = Tile.EmptyIn;
                        acc += 1;
                    }
                } else if (t == Tile.NorthSouth) {
                    in = !in;
                } else if (t == Tile.WestEast) {
                    // just stay on edge
                } else {
                    if (!onHorizontalEdge) {
                        onHorizontalEdge = true;
                        horizontalEdgeStart = t;
                    } else {
                        if (horizontalEdgeStart == Tile.SouthEast and t == Tile.NorthWest or
                            horizontalEdgeStart == Tile.NorthEast and t == Tile.SouthWest)
                        {
                            in = !in;
                        }
                        onHorizontalEdge = false;
                    }
                }
            }
        }
        return acc;
    }

    pub fn connected(self: Field, point: Point) ![4]bool {
        var ret = [4]bool{ false, false, false, false };
        try for (self.at(point).connections) |c| {
            ret[@as(usize, @intCast(c))] = true;
        };
        return ret;
    }

    pub fn print(self: Field) void {
        const w: usize = @intCast(self.width);
        const h: usize = @intCast(self.height);

        var row: usize = 0;
        while (row < h) : (row += 1) {
            var col: usize = 0;
            while (col < w) : (col += 1) {
                const iData = (row * w) + col;
                util.print("{u}", .{Tile.toChar(self.data[iData])});
            }
            util.print("\n", .{});
        }
    }
};

pub fn task_01(field: Field) i32 {
    const loop = field.findLoop();
    defer field.allocator.free(loop);

    // for (loop) |p| {
    //     util.print("{}, {}\n", .{ p.col, p.row });
    // }

    return @intCast(loop.len / 2);
}

pub fn task_02(field: Field) i32 {
    _ = field;
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

    var field = Field.initFromInput(input, allocator);
    defer field.deinit();

    _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    field.fixStart();
    field.cleanLoop();

    const numInside = field.findInside();

    std.debug.print("Day 10 Solution 1: {}\n", .{task_01(field)});
    std.debug.print("Day 03 Solution 2: {}\n", .{numInside});

    field.print();
}
