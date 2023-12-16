const std = @import("std");
const util = @import("util");

const State = @import("state.zig").State;
const Range = @import("Range.zig");

pub fn printLine(line: []const State, allocator: std.mem.Allocator) void {
    var str = allocator.alloc(u8, line.len) catch unreachable;
    defer allocator.free(str);

    for (line, 0..) |s, i| {
        str[i] = s.toChar();
    }

    util.print("{s}", .{str});
}

// Takes a size and a number of ranges and converts it into an array with the ranges marked as Damaged
pub fn generate(size: i32, groups: []const Range, allocator: std.mem.Allocator) ![]State {
    var ret = allocator.alloc(State, @as(usize, @intCast(size))) catch unreachable;
    errdefer allocator.free(ret);

    for (ret) |*s| s.* = State.Operational;

    for (groups) |g| {
        //util.print("[{} -- {}]\n", .{ g.start, g.size });
        var i: usize = @intCast(g.start);
        while (i < @as(usize, @intCast(g.start + g.size))) : (i += 1) {
            ret[i] = State.Damaged;
        }
    }

    return ret;
}
