const std = @import("std");
const util = @import("util");

const State = @import("state.zig").State;
const Range = @import("Range.zig");

const util12 = @import("util.zig");

const OffsetCounter = @This();

max: i32,
offsets: []i32,
sizes: []i32,
allowedRanges: []Range,
requiredRanges: []Range,
allocator: std.mem.Allocator,
groups: []Range,
first: bool,

pub fn init(max: i32, sizes: []const i32, allowedRanges: []const Range, requiredRanges: []const Range, allocator: std.mem.Allocator) OffsetCounter {
    var sizes_ = allocator.alloc(i32, sizes.len) catch unreachable;
    @memcpy(sizes_, sizes);

    var allowedRanges_ = allocator.alloc(Range, allowedRanges.len) catch unreachable;
    @memcpy(allowedRanges_, allowedRanges);

    var requiredRanges_ = allocator.alloc(Range, requiredRanges.len) catch unreachable;
    @memcpy(requiredRanges_, requiredRanges);

    var offsets = allocator.alloc(i32, sizes.len) catch unreachable;
    for (offsets) |*o| o.* = 0;

    var groups = allocator.alloc(Range, sizes.len) catch unreachable;

    return .{
        .max = max, //
        .offsets = offsets,
        .sizes = sizes_,
        .allowedRanges = allowedRanges_,
        .requiredRanges = requiredRanges_,
        .allocator = allocator,
        .groups = groups,
        .first = true,
    };
}

pub fn deinit(self: *OffsetCounter) void {
    self.allocator.free(self.offsets);
    self.allocator.free(self.sizes);
    self.allocator.free(self.groups);
    self.allocator.free(self.allowedRanges);
    self.allocator.free(self.requiredRanges);
}

pub fn makeGroups(self: OffsetCounter) []Range {
    var groups = self.allocator.alloc(Range, self.sizes.len) catch unreachable;

    groups[0] = .{ .start = self.offsets[0], .size = self.sizes[0] };

    for (self.sizes[1..], 1..) |r, i| {
        groups[i] = .{ .start = groups[i - 1].behindLast() + self.offsets[i] + 1, .size = r };
    }

    return groups;
}

pub fn makeGroups_(self: OffsetCounter) void {
    self.groups[0] = .{ .start = self.offsets[0], .size = self.sizes[0] };

    for (self.sizes[1..], 1..) |r, i| {
        self.groups[i] = .{ .start = self.groups[i - 1].behindLast() + self.offsets[i] + 1, .size = r };
    }
}

pub fn next(self: *OffsetCounter) ?[]Range {
    if (self.first) {
        self.first = false;
        var groups = self.makeGroups();
        if (groups[groups.len - 1].last() > self.max) {
            self.allocator.free(groups);
            return null;
        } else {
            return groups;
        }
    }

    var i = self.offsets.len - 1;
    self.offsets[i] += 1;

    var groups = self.makeGroups();

    while (groups[groups.len - 1].last() > self.max) {
        self.allocator.free(groups);

        self.offsets[i] = 0;
        if (i > 0) {
            i -= 1;
            self.offsets[i] += 1;
        } else {
            return null;
        }

        groups = self.makeGroups();
    }

    return groups;
}

pub fn next_(self: *OffsetCounter) ?[]Range {
    if (self.first) {
        self.first = false;
        self.makeGroups_();
        if (self.groups[self.groups.len - 1].last() > self.max) {
            return null;
        } else {
            return self.groups;
        }
    }

    var i = self.offsets.len - 1;
    self.offsets[i] += 1;

    self.makeGroups_();

    while (self.groups[self.groups.len - 1].last() > self.max) {
        self.offsets[i] = 0;
        if (i > 0) {
            i -= 1;
            self.offsets[i] += 1;
        } else {
            return null;
        }

        self.makeGroups_();
    }

    return self.groups;
}
