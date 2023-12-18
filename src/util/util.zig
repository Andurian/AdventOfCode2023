const std = @import("std");

const out = @import("out.zig");
pub const print = out.print;

pub const field = @import("field.zig");
pub const Field = field.Field;
pub const Direction = field.Direction;
pub const Point = field.Point;

const InputSource = enum { Test, Arg };

pub fn readFile(filename: []const u8, allocator: std.mem.Allocator) ![][]u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    while (true) {
        var line = std.ArrayList(u8).init(allocator);
        defer line.deinit();

        reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (line.items.len > 0 and line.getLast() == '\r') {
            _ = line.pop();
        }

        try lines.append(try line.toOwnedSlice());
    }

    return try lines.toOwnedSlice();
}

pub fn contains(comptime T: type, list: std.ArrayList(T), val: T) bool {
    for (list.items) |item| {
        if (std.meta.eql(val, item)) {
            return true;
        }
    }
    return false;
}

pub fn appendIfNotContains(comptime T: type, list: *std.ArrayList(T), val: T) void {
    if (!contains(T, list.*, val)) {
        list.append(val) catch unreachable;
    }
}

pub fn sleep(seconds: u32) void {
    print("Sleeping", .{});
    for (0..seconds) |_| {
        std.time.sleep(1e9);
        print(".", .{});
    }
    print("\n", .{});
}

pub fn max2(comptime T: type, arr: []T) [2]T {
    var max_1: T = 0;
    var max_2: T = 0;
    for (arr) |i| {
        if (i > max_1) {
            max_2 = max_1;
            max_1 = i;
        } else if (i > max_2) {
            max_2 = i;
        }
    }
    return [_]T{ max_1, max_2 };
}

pub fn lcm(lhs: anytype, rhs: anytype) @TypeOf(lhs, rhs) {
    return (lhs * rhs) / std.math.gcd(lhs, rhs);
}

pub fn traits(comptime T: type) type {
    return struct {
        pub fn id(v: T) T {
            return v;
        }
    };
}

pub fn allEqual(comptime T: type, val: T, seq: []T) bool {
    for (seq) |v| {
        if (!std.meta.eql(v, val)) return false;
    }
    return true;
}

pub fn contains_(comptime T: type, seq: []const T, val: T) bool {
    for (seq) |v| {
        if (std.meta.eql(v, val)) {
            return true;
        }
    }
    return false;
}

const Extent = struct {
    minCol: i32 = std.math.maxInt(i32),
    maxCol: i32 = std.math.minInt(i32),
    minRow: i32 = std.math.maxInt(i32),
    maxRow: i32 = std.math.minInt(i32),
};

pub fn extent(arr: []const Point) Extent {
    var ret = Extent{};

    for (arr) |pos| {
        ret.minCol = @min(ret.minCol, pos.col);
        ret.maxCol = @max(ret.maxCol, pos.col);

        ret.minRow = @min(ret.minRow, pos.row);
        ret.maxRow = @max(ret.maxRow, pos.row);
    }
    return ret;
}
