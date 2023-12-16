const std = @import("std");
const util = @import("util");

const State = @import("state.zig").State;
const Range = @import("Range.zig");
const OffsetCounter = @import("OffsetCounter.zig");

const util12 = @import("util.zig");

const Reading = @This();

line: []State,
lineAsRangesCan: []Range,
lineAsRangesMust: []Range,
groups: []i32,
allocator: std.mem.Allocator,

fn parseGroups(line: []const u8, allocator: std.mem.Allocator) []i32 {
    var ret = std.ArrayList(i32).init(allocator);
    defer ret.deinit();

    var it = std.mem.tokenize(u8, line, ",");
    while (it.next()) |token| {
        const size = std.fmt.parseInt(i32, token, 10) catch unreachable;
        ret.append(size) catch unreachable;
    }

    return ret.toOwnedSlice() catch unreachable;
}

fn parseLine(line: []const u8, allocator: std.mem.Allocator) []State {
    var ret = allocator.alloc(State, line.len) catch unreachable;

    for (line, 0..) |c, i| {
        ret[i] = State.fromChar(c);
    }

    return ret;
}

fn parseLineAsRangesCan(line: []const State, allocator: std.mem.Allocator) []Range {
    var ret = std.ArrayList(Range).init(allocator);
    defer ret.deinit();

    var i: usize = 0;
    while (i < line.len) {
        if (line[i] == State.Operational) {
            i += 1;
            continue;
        }
        var j = i + 1;
        while (j < line.len and (line[j] == State.Damaged or line[j] == State.Unknown)) j += 1;
        ret.append(.{ .start = @intCast(i), .size = @intCast(j - i) }) catch unreachable;
        i = j + 1;
    }

    return ret.toOwnedSlice() catch unreachable;
}

fn parseLineAsRangesMust(line: []const State, allocator: std.mem.Allocator) []Range {
    var ret = std.ArrayList(Range).init(allocator);
    defer ret.deinit();

    var i: usize = 0;
    while (i < line.len) {
        if (line[i] != State.Damaged) {
            i += 1;
            continue;
        }
        var j = i + 1;
        while (j < line.len and line[j] == State.Damaged) j += 1;
        ret.append(.{ .start = @intCast(i), .size = @intCast(j - i) }) catch unreachable;
        i = j + 1;
    }

    return ret.toOwnedSlice() catch unreachable;
}

pub fn fromLine(line: []const u8, allocator: std.mem.Allocator) Reading {
    var it = std.mem.tokenize(u8, line, " ");

    const springs = parseLine(it.next().?, allocator);
    const groups = parseGroups(it.next().?, allocator);
    const lineAsRangesCan = parseLineAsRangesCan(springs, allocator);
    const lineAsRangesMust = parseLineAsRangesMust(springs, allocator);

    return .{
        .line = springs, //
        .lineAsRangesCan = lineAsRangesCan, //
        .lineAsRangesMust = lineAsRangesMust, //
        .groups = groups, //
        .allocator = allocator,
    };
}

pub fn deinit(self: *Reading) void {
    self.allocator.free(self.line);
    self.allocator.free(self.groups);
    self.allocator.free(self.lineAsRangesCan);
    self.allocator.free(self.lineAsRangesMust);
}

pub fn print(self: Reading) void {
    util12.printLine(self.line, self.allocator);
    util.print(" ", .{});
    for (self.groups) |g| util.print("{}, ", .{g});
    util.print("\n", .{});

    var l = util12.generate(@intCast(self.line.len), self.lineAsRangesCan, self.allocator) catch unreachable;
    defer self.allocator.free(l);
    util12.printLine(l, self.allocator);
    util.print("\n", .{});

    var q = util12.generate(@intCast(self.line.len), self.lineAsRangesMust, self.allocator) catch unreachable;
    defer self.allocator.free(q);
    util12.printLine(q, self.allocator);
    util.print("\n", .{});
}

pub fn isValidProposal(self: Reading, proposal: []const Range) bool {
    for (proposal) |p| {
        if (!p.isContainedInAny(self.lineAsRangesCan)) return false;
    }

    for (self.lineAsRangesMust) |p| {
        if (!p.isContainedInAny(proposal)) return false;
    }

    return true;
}

pub fn isValidRange(self: Reading, proposal: Range) bool {
    const behindLast: usize = @intCast(proposal.behindLast());

    var i: usize = @intCast(proposal.start);
    while (i < behindLast) : (i += 1) {
        if (self.line[i] == State.Operational) return false;
    }

    const behindOk = behindLast == self.length() or self.line[behindLast] != State.Damaged;
    const beforeOk = proposal.start == 0 or self.line[@intCast(proposal.start - 1)] != State.Damaged;

    return beforeOk and behindOk;
}

pub fn length(self: Reading) usize {
    return self.line.len;
}

pub fn generatePossibilities(self: Reading) u64 {
    var acc: u64 = 0;
    const len: i32 = @intCast(self.line.len);

    var counter = OffsetCounter.init(len - 1, self.groups, self.lineAsRangesCan, self.lineAsRangesMust, self.allocator);
    defer counter.deinit();

    while (counter.next_()) |proposalGroups| {
        if (self.isValidProposal(proposalGroups)) {
            acc += 1;
        }
    }

    return acc;
}

pub fn expand(self: Reading) Reading {
    var line = self.allocator.alloc(State, 5 * (self.line.len + 1) - 1) catch unreachable;
    for (self.line, 0..) |s, i| {
        line[0 * (self.line.len + 1) + i] = s;
        line[1 * (self.line.len + 1) + i] = s;
        line[2 * (self.line.len + 1) + i] = s;
        line[3 * (self.line.len + 1) + i] = s;
        line[4 * (self.line.len + 1) + i] = s;
    }
    line[1 * (self.line.len + 1) - 1] = State.Unknown;
    line[2 * (self.line.len + 1) - 1] = State.Unknown;
    line[3 * (self.line.len + 1) - 1] = State.Unknown;
    line[4 * (self.line.len + 1) - 1] = State.Unknown;

    var groups = self.allocator.alloc(i32, 5 * self.groups.len) catch unreachable;
    for (self.groups, 0..) |g, i| {
        groups[0 * self.groups.len + i] = g;
        groups[1 * self.groups.len + i] = g;
        groups[2 * self.groups.len + i] = g;
        groups[3 * self.groups.len + i] = g;
        groups[4 * self.groups.len + i] = g;
    }

    const lineAsRangesCan = parseLineAsRangesCan(line, self.allocator);
    const lineAsRangesMust = parseLineAsRangesMust(line, self.allocator);

    return .{
        .line = line, //
        .groups = groups, //
        .allocator = self.allocator,
        .lineAsRangesCan = lineAsRangesCan,
        .lineAsRangesMust = lineAsRangesMust,
    };
}
