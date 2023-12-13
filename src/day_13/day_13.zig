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

const Field = struct {
    width: i32,
    height: i32,
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) Field {
        const height = input.len;
        const width = input[0].len;
        const s: usize = width * height;
        var data = allocator.alloc(u8, s) catch unreachable;

        var row: usize = 0;
        while (row < height) : (row += 1) {
            var col: usize = 0;
            while (col < width) : (col += 1) {
                const i = row * width + col;
                data[i] = input[row][col];
            }
        }

        return Field{
            .width = @intCast(width), //
            .height = @intCast(height), //
            .data = data, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Field) void {
        self.allocator.free(self.data);
    }

    pub fn contains(self: Field, point: Point) bool {
        return point.row >= 0 and point.row < self.height and point.col >= 0 and point.col < self.width;
    }

    pub fn at(self: Field, point: Point) !u8 {
        if (!self.contains(point)) {
            return error.OutOfFiledAccess;
        }
        const pos: usize = @intCast(point.row * self.width + point.col);
        return self.data[pos];
    }

    pub fn set(self: *Field, point: Point, val: u8) void {
        const pos: usize = @intCast(point.row * self.width + point.col);
        self.data[pos] = val;
    }

    pub fn getRow(self: Field, row: i32) []const u8 {
        const start: usize = @intCast(row * self.width);
        const end: usize = @intCast((row + 1) * self.width);
        return self.data[start..end];
    }

    pub fn getCol(self: Field, col: i32, allocator: std.mem.Allocator) []u8 {
        var ret = allocator.alloc(u8, @intCast(self.height)) catch unreachable;

        var row: i32 = 0;
        while (row < self.height) : (row += 1) {
            ret[@as(usize, @intCast(row))] = self.at(.{ .row = row, .col = col }) catch unreachable;
        }
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
                util.print("{u}", .{self.data[iData]});
            }
            util.print("\n", .{});
        }
    }
};

pub fn isSymmetric(line: []const u8, i: usize) bool {
    const p1 = line[0..i];
    const p2 = line[i..];

    const max = @min(p1.len, p2.len);
    var j: usize = 0;
    while (j < max) : (j += 1) {
        if (p1[p1.len - 1 - j] != p2[j]) return false;
    }

    return true;
}

test isSymmetric {
    try std.testing.expect(isSymmetric("#.##..##.", 5));
    try std.testing.expect(!isSymmetric("#.##..##.", 6));
    try std.testing.expect(!isSymmetric("#...##..#", 5));
    try std.testing.expect(isSymmetric("#...##..#", 0));
    try std.testing.expect(isSymmetric("..#.##.#...##", 12));
}

pub fn findSymmetryAxisHorizontal(field: Field, allocator: std.mem.Allocator) []usize {
    var candidates = allocator.alloc(bool, @intCast(field.width)) catch unreachable;
    defer allocator.free(candidates);

    for (candidates) |*c| c.* = true;
    candidates[0] = false;
    //candidates[candidates.len - 1] = false;

    var row: i32 = 0;
    while (row < field.height) : (row += 1) {
        const row_ = field.getRow(row);
        var doContinue: bool = false;
        for (candidates, 0..) |*c, i| {
            if (!c.*) continue;
            if (!isSymmetric(row_, i)) {
                c.* = false;
                continue;
            } else {
                doContinue = true;
            }
        }
        if (!doContinue) break;
    }

    var ret = std.ArrayList(usize).init(allocator);
    defer ret.deinit();

    for (candidates, 0..) |c, i| {
        if (c) {
            ret.append(i) catch unreachable;
        }
    }

    return ret.toOwnedSlice() catch unreachable;
}

pub fn findSymmetryAxisVertical(field: Field, allocator: std.mem.Allocator) []usize {
    var candidates = allocator.alloc(bool, @intCast(field.height)) catch unreachable;
    defer allocator.free(candidates);

    for (candidates) |*c| c.* = true;
    candidates[0] = false;
    //candidates[candidates.len - 1] = false;

    var col: i32 = 0;
    while (col < field.width) : (col += 1) {
        const col_ = field.getCol(col, allocator);
        defer allocator.free(col_);
        var doContinue: bool = false;
        for (candidates, 0..) |*c, i| {
            if (!c.*) continue;
            if (!isSymmetric(col_, i)) {
                c.* = false;
                continue;
            } else {
                doContinue = true;
            }
        }
        if (!doContinue) break;
    }

    var ret = std.ArrayList(usize).init(allocator);
    defer ret.deinit();

    for (candidates, 0..) |c, i| {
        if (c) {
            ret.append(i) catch unreachable;
        }
    }

    return ret.toOwnedSlice() catch unreachable;
}

const Dir = enum { Horizontal, Vertical };
const Axis = struct {
    direction: Dir,
    idx: usize,

    pub fn num(self: Axis) usize {
        if (self.direction == Dir.Horizontal) return self.idx;
        return 100 * self.idx;
    }
};

pub fn symmetryNumbers(field: Field, allocator: std.mem.Allocator) []Axis {
    var ret = std.ArrayList(Axis).init(allocator);
    defer ret.deinit();

    var hor = findSymmetryAxisHorizontal(field, allocator);
    defer allocator.free(hor);

    var ver = findSymmetryAxisVertical(field, allocator);
    defer allocator.free(ver);

    for (hor) |h| ret.append(.{ .direction = Dir.Horizontal, .idx = h }) catch unreachable;
    for (ver) |v| ret.append(.{ .direction = Dir.Vertical, .idx = v }) catch unreachable;

    return ret.toOwnedSlice() catch unreachable;
}

pub fn fixSmudge(field: *Field, allocator: std.mem.Allocator) usize {
    var initialNum = symmetryNumbers(field.*, allocator);
    defer allocator.free(initialNum);

    var row: i32 = 0;
    while (row < field.height) : (row += 1) {
        var col: i32 = 0;
        while (col < field.width) : (col += 1) {
            const p = Point{ .row = row, .col = col };
            if (field.at(p) catch unreachable == '#') continue;

            field.set(p, '#');
            defer field.set(p, '.');

            var newNum = symmetryNumbers(field.*, allocator);
            defer allocator.free(newNum);

            if (newNum.len == 0) continue;
            for (newNum) |n| {
                if (!std.meta.eql(n, initialNum[0])) return n.num();
            }
        }
    }
    return 0;
}

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Field {
    var ret = std.ArrayList(Field).init(allocator);
    defer ret.deinit();

    var i: usize = 0;
    while (i < input.len) {
        var j: usize = i + 1;
        while (j < input.len and input[j].len != 0) {
            j += 1;
        }
        var f = Field.initFromInput(input[i..j], allocator);
        ret.append(f) catch unreachable;
        if (j >= input.len) break;
        i = j + 1;
    }

    return ret.toOwnedSlice() catch unreachable;
}

pub fn task_01(fields: []const Field, allocator: std.mem.Allocator) usize {
    var acc: usize = 0;

    for (fields) |f| {
        var n = symmetryNumbers(f, allocator);
        defer allocator.free(n);
        acc += n[0].num();
    }

    return acc;
}

pub fn task_02(fields: []Field, allocator: std.mem.Allocator) usize {
    var acc: usize = 0;
    for (fields) |*f| {
        acc += fixSmudge(f, allocator);
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

    var fields = parseInput(input, allocator);
    defer allocator.free(fields);
    defer for (fields) |*f| f.deinit();

    std.debug.print("Day 13 Solution 1: {}\n", .{task_01(fields, allocator)});
    std.debug.print("Day 13 Solution 2: {}\n", .{task_02(fields, allocator)});
}
