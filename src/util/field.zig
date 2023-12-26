const std = @import("std");
const out = @import("out.zig");

pub const Direction = enum(u8) {
    North,
    East,
    South,
    West,

    pub fn lt(_: void, lhs: Direction, rhs: Direction) bool {
        return @intFromEnum(lhs) < @intFromEnum(rhs);
    }

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            Direction.North => Direction.South,
            Direction.East => Direction.West,
            Direction.South => Direction.North,
            Direction.West => Direction.East,
        };
    }

    pub fn toChar(self: Direction) u8 {
        return switch (self) {
            Direction.North => '^',
            Direction.East => '>',
            Direction.South => 'v',
            Direction.West => '<',
        };
    }
};

pub const Point = struct {
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

pub fn Field(comptime T: type) type {
    return struct {
        const Self = @This();

        width: i32,
        height: i32,
        data: []T,
        allocator: std.mem.Allocator,

        const Iterator = struct {
            row: i32 = 0,
            col: i32 = 0,

            f: Self,

            pub fn next(self: *Iterator) ?T {
                if (self.row >= self.f.height) return null;

                const i: usize = @intCast(self.row * self.f.width + self.col);
                const ret = self.f.data[i];

                if (self.col == self.f.width - 1) {
                    self.col = 0;
                    self.row += 1;
                } else {
                    self.col += 1;
                }

                return ret;
            }
        };

        const PositionIterator = struct {
            row: i32 = 0,
            col: i32 = 0,

            f: Self,

            pub fn next(self: *PositionIterator) ?Point {
                if (self.row >= self.f.height) return null;
                const ret = Point{ .row = self.row, .col = self.col };

                if (self.col == self.f.width - 1) {
                    self.col = 0;
                    self.row += 1;
                } else {
                    self.col += 1;
                }

                return ret;
            }
        };

        pub fn initFromInput(input: [][]const u8, comptime convert: fn (u8) T, allocator: std.mem.Allocator) Self {
            const height = input.len;
            const width = input[0].len;
            var data = allocator.alloc(T, width * height) catch unreachable;

            var row: usize = 0;
            while (row < height) : (row += 1) {
                var col: usize = 0;
                while (col < width) : (col += 1) {
                    const i = row * width + col;
                    data[i] = convert(input[row][col]);
                }
            }

            return Self{
                .width = @intCast(width), //
                .height = @intCast(height), //
                .data = data, //
                .allocator = allocator,
            };
        }

        pub fn initWithDefault(width: i32, height: i32, val: T, allocator: std.mem.Allocator) Self {
            var data = allocator.alloc(T, @intCast(width * height)) catch unreachable;
            @memset(data, val);

            return Self{
                .width = width, //
                .height = height, //
                .data = data, //
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn contains(self: Self, point: Point) bool {
            return point.row >= 0 and point.row < self.height and point.col >= 0 and point.col < self.width;
        }

        pub fn at(self: Self, point: Point) !T {
            if (!self.contains(point)) {
                return error.OutOfFiledAccess;
            }
            const pos: usize = @intCast(point.row * self.width + point.col);
            return self.data[pos];
        }

        pub fn set(self: *Self, point: Point, val: T) void {
            const pos: usize = @intCast(point.row * self.width + point.col);
            self.data[pos] = val;
        }

        pub fn getRow(self: Self, row: i32) []const T {
            const start: usize = @intCast(row * self.width);
            const end: usize = @intCast((row + 1) * self.width);
            return self.data[start..end];
        }

        pub fn getCol(self: Self, col: i32, allocator: std.mem.Allocator) []u8 {
            var ret = allocator.alloc(u8, @intCast(self.height)) catch unreachable;

            var row: i32 = 0;
            while (row < self.height) : (row += 1) {
                ret[@as(usize, @intCast(row))] = self.at(.{ .row = row, .col = col }) catch unreachable;
            }
            return ret;
        }

        pub fn iterator(self: Self) Iterator {
            return .{ .f = self };
        }

        pub fn positionIterator(self: Self) PositionIterator {
            return .{ .f = self };
        }

        pub fn print(self: Self, comptime toChar: fn (T) u8) void {
            const w: usize = @intCast(self.width);
            const h: usize = @intCast(self.height);

            var row: usize = 0;
            while (row < h) : (row += 1) {
                var col: usize = 0;
                while (col < w) : (col += 1) {
                    const iData = (row * w) + col;
                    out.print("{c}", .{toChar(self.data[iData])});
                }
                out.print("\n", .{});
            }
        }

        pub fn debugPrint(self: Self) void {
            const w: usize = @intCast(self.width);
            const h: usize = @intCast(self.height);

            var row: usize = 0;
            while (row < h) : (row += 1) {
                var col: usize = 0;
                while (col < w) : (col += 1) {
                    const iData = (row * w) + col;
                    out.print("{:5}", .{self.data[iData]});
                }
                out.print("\n", .{});
            }
        }

        pub fn clone(self: Self) Field(T) {
            var data = self.allocator.alloc(T, @intCast(self.width * self.height)) catch unreachable;
            @memcpy(data, self.data);

            return .{ .data = data, .width = self.width, .height = self.height, .allocator = self.allocator };
        }
    };
}
