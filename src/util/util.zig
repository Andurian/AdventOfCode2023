const std = @import("std");

const InputSource = enum { Test, Arg };

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

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
