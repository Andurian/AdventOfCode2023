const std = @import("std");

const closure = @import("closure.zig");

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

        if (line.getLast() == '\r') {
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
