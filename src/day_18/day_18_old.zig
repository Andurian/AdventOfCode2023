const std = @import("std");
const util = @import("util");

// Solved Task 1 in a way similar to Day 10 but is not feasible for Task 2.
// Nevertheless I still might need the dynamic field somewhere.
// Also it allowed generating visual output which is nice.

const Instruction = struct {
    direction: util.Direction,
    distance: i32,
    color: [6]u8,

    pub fn fromStr(str: []const u8) Instruction {
        var it = std.mem.tokenize(u8, str, " (#)");
        const direction: util.Direction = switch (it.next().?[0]) {
            'R' => .East,
            'U' => .North,
            'D' => .South,
            'L' => .West,
            else => unreachable,
        };

        const distance: i32 = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;

        var color: [6]u8 = undefined;
        @memcpy(&color, it.next().?);

        return .{
            .direction = direction, //
            .distance = distance,
            .color = color,
        };
    }
};

const Tile = struct {
    const Kind = enum(u8) { //
        Empty,
        EmptyIn,
        NorthSouth,
        WestEast,
        NorthWest,
        NorthEast,
        SouthWest,
        SouthEast,

        pub fn toChar(t: Kind) u21 {
            return switch (t) {
                .Empty => '.',
                .EmptyIn => 'I',
                .NorthSouth => '│',
                .WestEast => '─',
                .NorthEast => '└',
                .NorthWest => '┘',
                .SouthEast => '┌',
                .SouthWest => '┐',
            };
        }
    };

    kind: Kind,
    color: [6]u8,
};

pub fn tileTypeCorner(previous: util.Direction, next: util.Direction) Tile.Kind {
    switch (previous) {
        .North => switch (next) {
            .North => unreachable,
            .East => return .SouthEast,
            .South => unreachable,
            .West => return .SouthWest,
        },
        .East => switch (next) {
            .North => return .NorthWest,
            .East => unreachable,
            .South => return .SouthWest,
            .West => unreachable,
        },
        .South => switch (next) {
            .North => unreachable,
            .East => return .NorthEast,
            .South => unreachable,
            .West => return .NorthWest,
        },
        .West => switch (next) {
            .North => return .NorthEast,
            .East => unreachable,
            .South => return .SouthEast,
            .West => unreachable,
        },
    }
}

pub fn tileTypeStraight(d: util.Direction) Tile.Kind {
    return switch (d) {
        .North => .NorthSouth,
        .East => .WestEast,
        .South => .NorthSouth,
        .West => .WestEast,
    };
}

const Extent = struct {
    minCol: i32 = std.math.maxInt(i32),
    maxCol: i32 = std.math.minInt(i32),
    minRow: i32 = std.math.maxInt(i32),
    maxRow: i32 = std.math.minInt(i32),
};

const DynamicField = struct {
    tiles: std.AutoHashMap(util.Point, Tile),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DynamicField {
        return .{ //
            .tiles = std.AutoHashMap(util.Point, Tile).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DynamicField) void {
        self.tiles.deinit();
    }

    pub fn build(self: *DynamicField, instructions: []const Instruction) void {
        var currentPos = util.Point{ .row = 0, .col = 0 };

        for (instructions, 0..) |instruction, index| {
            //util.print("{any}\n", .{instruction});
            var i: i32 = 0;
            while (i < instruction.distance) : (i += 1) {
                const direction = instruction.direction;

                currentPos = currentPos.neighbor(direction);
                var tileType: Tile.Kind = .NorthSouth;
                if (i < instruction.distance - 1) {
                    tileType = tileTypeStraight(direction);
                    //util.print("\tContinue with: {any} -> {any}\n", .{ direction, tileType });
                } else {
                    const nextIndex = if (index < instructions.len - 1) index + 1 else 0;
                    const nextDirection = instructions[nextIndex].direction;
                    //util.print("\tConnect to: {} -> {any} -> {any}\n", .{ nextIndex, nextDirection, tileType });
                    tileType = tileTypeCorner(direction, nextDirection);
                }

                //util.print("\tPut: {any}, {any}\n", .{ currentPos, tileType });
                self.tiles.put(currentPos, .{ //
                    .kind = tileType,
                    .color = instruction.color,
                }) catch unreachable;
            }

            //self.print();
        }
    }

    pub fn carve(self: *DynamicField) void {
        const ext = self.extent();
        var row = ext.minRow - 1;
        while (row < ext.maxRow + 2) : (row += 1) {
            var col = ext.minCol - 1;
            var in: bool = false;
            var onHorizontalEdge: bool = false;
            var horizontalEdgeStart: Tile.Kind = undefined;
            while (col < ext.maxCol + 2) : (col += 1) {
                const p = util.Point{ .row = row, .col = col };
                const t = self.tiles.get(p);

                if (t == null or t.?.kind == Tile.Kind.Empty) {
                    if (in) {
                        self.tiles.put(p, .{ .kind = Tile.Kind.EmptyIn, .color = [_]u8{'0'} ** 6 }) catch unreachable;
                    }
                } else if (t.?.kind == Tile.Kind.NorthSouth) {
                    in = !in;
                } else if (t.?.kind == Tile.Kind.WestEast) {
                    // just stay on edge
                } else {
                    if (!onHorizontalEdge) {
                        onHorizontalEdge = true;
                        horizontalEdgeStart = t.?.kind;
                    } else {
                        if (horizontalEdgeStart == Tile.Kind.SouthEast and t.?.kind == Tile.Kind.NorthWest or
                            horizontalEdgeStart == Tile.Kind.NorthEast and t.?.kind == Tile.Kind.SouthWest)
                        {
                            in = !in;
                        }
                        onHorizontalEdge = false;
                    }
                }
            }
        }
    }

    pub fn extent(self: DynamicField) Extent {
        var ret = Extent{};
        var it = self.tiles.keyIterator();
        while (it.next()) |pos| {
            ret.minCol = @min(ret.minCol, pos.col);
            ret.maxCol = @max(ret.maxCol, pos.col);

            ret.minRow = @min(ret.minRow, pos.row);
            ret.maxRow = @max(ret.maxRow, pos.row);
        }
        return ret;
    }

    pub fn print(self: DynamicField) void {
        const ext = self.extent();
        var row = ext.minRow - 1;
        while (row < ext.maxRow + 2) : (row += 1) {
            var col = ext.minCol - 1;
            while (col < ext.maxCol + 2) : (col += 1) {
                const pos = util.Point{ .row = row, .col = col };
                const tile = self.tiles.get(pos);
                if (tile == null) {
                    util.print("{u}", .{Tile.Kind.Empty.toChar()});
                } else {
                    util.print("{u}", .{tile.?.kind.toChar()});
                }
            }
            util.print("\n", .{});
        }
    }
};

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Instruction {
    var arr = std.ArrayList(Instruction).init(allocator);
    defer arr.deinit();

    for (input) |line| {
        arr.append(Instruction.fromStr(line)) catch unreachable;
    }

    return arr.toOwnedSlice() catch unreachable;
}

pub fn makePolygon(instructions: []const Instruction, allocator: std.mem.Allocator) []util.Point {
    var ret = allocator.alloc(util.Point, instructions.len) catch unreachable;

    var currentPos = util.Point{ .row = 0, .col = 0 };
    ret[0] = currentPos;
    for (instructions, 0..) |instruction, i| {
        switch (instruction.direction) {
            .North => currentPos.row -= instruction.distance,
            .South => currentPos.row += instruction.distance,
            .West => currentPos.col -= instruction.distance,
            .East => currentPos.col += instruction.distance,
        }
        if (i != instructions.len - 1) {
            ret[i + 1] = currentPos;
        }
    }

    const extent = util.extent(ret);
    for (ret) |*p| {
        p.col -= extent.minCol;
        p.row -= extent.minRow;
    }

    return ret;
}

pub fn areaTriangle(poly: []const util.Point) i64 {
    var acc: i64 = 0;
    for (poly, 0..) |p1, i| {
        const p2 = if (i == poly.len - 1) poly[0] else poly[i + 1];
        //acc += @intCast((p1.row + p2.row) * (p1.col - p2.col));
        const v: i64 = @intCast((p1.col * p2.row) - (p1.row * p2.col));

        util.print("{} -> {} : ({} * {}) + ({} * {}) = {}\n", .{ p1, p2, p1.col, p2.row, p1.row, p2.col, v });
        acc += v;
    }
    return acc;
}

pub fn areaTrapezoid(poly: []const util.Point) i64 {
    var acc: i64 = 0;
    for (poly, 0..) |p1, i| {
        const p2 = if (i == poly.len - 1) poly[0] else poly[i + 1];

        const v: i64 = @intCast((p1.row + p2.row) * (p1.col - p2.col));

        util.print("{} -> {} : ({} + {}) * ({} - {}) = {}\n", .{ p1, p2, p1.row, p2.row, p1.col, p2.col, v });
        acc += v;
    }
    return acc;
}

pub fn task_01(instructions: []const Instruction, allocator: std.mem.Allocator) u32 {
    var field = DynamicField.init(allocator);
    defer field.deinit();

    //_ = std.os.windows.kernel32.SetConsoleOutputCP(65001);

    field.build(instructions);
    field.carve();

    return field.tiles.count();
}

pub fn task_01_2(instructions: []const Instruction, allocator: std.mem.Allocator) void {
    var poly = makePolygon(instructions, allocator);
    defer allocator.free(poly);

    var debugPoly = [_]util.Point{
        .{ .row = 0, .col = 0 },
        .{ .row = 0, .col = 3 },
        .{ .row = 2, .col = 3 },
        .{ .row = 2, .col = 4 },
        .{ .row = 5, .col = 4 },
        .{ .row = 5, .col = 1 },
        .{ .row = 3, .col = 1 },
        .{ .row = 3, .col = 0 },
    };
    _ = debugPoly;

    var debugPoly2 = [_]util.Point{
        .{ .row = 0, .col = 0 },
        .{ .row = 0, .col = 4 },
        .{ .row = 2, .col = 4 },
        .{ .row = 2, .col = 5 },
        .{ .row = 6, .col = 5 },
        .{ .row = 6, .col = 1 },
        .{ .row = 4, .col = 1 },
        .{ .row = 4, .col = 0 },
    };

    // for (poly) |p|
    //     util.print("{any}\n", .{p});

    util.print("{}\n", .{areaTrapezoid(&debugPoly2)});
    util.print("{}\n", .{areaTriangle(&debugPoly2)});
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

    var instructions = parseInput(input, allocator);
    defer allocator.free(instructions);

    task_01_2(instructions, allocator);

    //std.debug.print("Day 16 Solution 1: {}\n", .{task_01(field, allocator)});
    //std.debug.print("Day 16 Solution 2: {}\n", .{task_02(field, allocator)});
}
