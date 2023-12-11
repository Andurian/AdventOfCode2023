const std = @import("std");
const util = @import("util");

const Point = struct {
    row: i64,
    col: i64,

    pub fn manhattanDistance(self: Point, other: Point) i64 {
        const dRow = std.math.absInt(other.row - self.row) catch unreachable;
        const dCol = std.math.absInt(other.col - self.col) catch unreachable;

        return dRow + dCol;
    }
};

const Sky = struct {
    galaxies: []Point,
    rows: i64,
    cols: i64,
    allocator: std.mem.Allocator,

    pub fn fromInput(input: [][]const u8, allocator: std.mem.Allocator) Sky {
        var arr = std.ArrayList(Point).init(allocator);
        defer arr.deinit();

        for (input, 0..) |line, row| {
            for (line, 0..) |c, col| {
                if (c == '#') {
                    arr.append(.{ .row = @intCast(row), .col = @intCast(col) }) catch unreachable;
                }
            }
        }

        return .{
            .galaxies = arr.toOwnedSlice() catch unreachable, //
            .rows = @intCast(input.len),
            .cols = @intCast(input[0].len),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Sky) void {
        self.allocator.free(self.galaxies);
    }

    pub fn findEmptyRows(self: Sky) []i64 {
        var arr = std.ArrayList(i64).init(self.allocator);
        defer arr.deinit();

        var row: i64 = 0;
        loop: while (row < self.rows) : (row += 1) {
            for (self.galaxies) |g| {
                if (g.row == row) continue :loop;
            }
            arr.append(row) catch unreachable;
        }

        return arr.toOwnedSlice() catch unreachable;
    }

    pub fn findEmptyCols(self: Sky) []i64 {
        var arr = std.ArrayList(i64).init(self.allocator);
        defer arr.deinit();

        var col: i64 = 0;
        loop: while (col < self.cols) : (col += 1) {
            for (self.galaxies) |g| {
                if (g.col == col) continue :loop;
            }
            arr.append(col) catch unreachable;
        }

        return arr.toOwnedSlice() catch unreachable;
    }

    pub fn expand(self: Sky, d: i64) Sky {
        var emptyRows = self.findEmptyRows();
        defer self.allocator.free(emptyRows);

        var emptyCols = self.findEmptyCols();
        defer self.allocator.free(emptyCols);

        var galaxies = self.allocator.alloc(Point, self.galaxies.len) catch unreachable;
        @memcpy(galaxies, self.galaxies);

        var i: usize = 0;
        while (i < emptyRows.len) : (i += 1) {
            const expandingRow = emptyRows[i];
            for (galaxies) |*g| {
                if (g.row > expandingRow) {
                    g.row += d;
                }
            }
            var j = i + 1;
            while (j < emptyRows.len) : (j += 1) {
                emptyRows[j] = emptyRows[j] + d;
            }
        }
        const rows = self.rows + @as(i64, @intCast(emptyRows.len)) * d;

        i = 0;
        while (i < emptyCols.len) : (i += 1) {
            const expandingCol = emptyCols[i];
            for (galaxies) |*g| {
                if (g.col > expandingCol) {
                    g.col += d;
                }
            }
            var j = i + 1;
            while (j < emptyCols.len) : (j += 1) {
                emptyCols[j] += d;
            }
        }

        const cols = self.cols + @as(i64, @intCast(emptyCols.len)) * d;

        return .{
            .galaxies = galaxies,
            .rows = rows,
            .cols = cols,
            .allocator = self.allocator,
        };
    }

    pub fn allDistances(self: Sky) i64 {
        var acc: i64 = 0;
        var i: usize = 0;
        while (i < self.galaxies.len) : (i += 1) {
            const g1 = self.galaxies[i];
            var j: usize = i + 1;
            while (j < self.galaxies.len) : (j += 1) {
                const g2 = self.galaxies[j];
                acc += g1.manhattanDistance(g2);
            }
        }
        return acc;
    }

    pub fn print(self: Sky) void {
        for (self.galaxies) |g| util.print("[{}, {}] ", .{ g.row, g.col });
        util.print("\n", .{});
    }
};

pub fn expandedDistances(sky: Sky, factor: i64) i64 {
    var skyExpanded = sky.expand(factor - 1);
    defer skyExpanded.deinit();

    return skyExpanded.allDistances();
}

pub fn task_01(sky: Sky) i64 {
    return expandedDistances(sky, 2);
}

pub fn task_02(sky: Sky) i64 {
    return expandedDistances(sky, 1000000);
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_11.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var sky = Sky.fromInput(input, allocator);
    defer sky.deinit();

    try std.testing.expectEqual(@as(i64, 374), task_01(sky));
    try std.testing.expectEqual(@as(i64, 1030), expandedDistances(sky, 10));
    try std.testing.expectEqual(@as(i64, 8410), expandedDistances(sky, 100));
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

    var sky = Sky.fromInput(input, allocator);
    defer sky.deinit();

    std.debug.print("Day 10 Solution 1: {}\n", .{task_01(sky)});
    std.debug.print("Day 10 Solution 1: {}\n", .{task_02(sky)});
}
