const std = @import("std");
const util = @import("util");

const State = @import("state.zig").State;
const Range = @import("Range.zig");
const Reading = @import("Reading.zig");

const Key = struct { start: usize, numPlacedGroups: usize };

const Solver = @This();

reading: *const Reading,
solutionsFor: std.AutoHashMap(Key, u64),
allocator: std.mem.Allocator,

pub fn init(reading: *const Reading, allocator: std.mem.Allocator) Solver {
    return .{
        .reading = reading,
        .solutionsFor = std.AutoHashMap(Key, u64).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Solver) void {
    self.solutionsFor.deinit();
}

fn solveWithCache(self: *Solver, start: usize, numPlacedGroups: usize) u64 {
    const key: Key = .{ .start = start, .numPlacedGroups = numPlacedGroups };
    var value = self.solutionsFor.get(key);
    if (value) |v| {
        return v;
    } else {
        const solution = self.solve_(start, numPlacedGroups);
        self.solutionsFor.put(key, solution) catch unreachable;
        return solution;
    }
}

fn solve_(self: *Solver, start: usize, numPlacedGroups: usize) u64 {
    const groupSize: usize = @intCast(self.reading.groups[numPlacedGroups]);
    var validCounter: u64 = 0;
    var offset: usize = 0;
    while (start + offset + groupSize <= self.reading.length()) : (offset += 1) {
        const range = Range{ .start = @intCast(start + offset), .size = @intCast(groupSize) };

        // If we do not cover a damaged cell we cannot be valid any more
        if (util.contains_(State, self.reading.line[start .. start + offset], State.Damaged)) break;

        // Range itself is not valid
        if (!self.reading.isValidRange(range)) continue;

        const behindLast: usize = @intCast(range.behindLast());

        if (numPlacedGroups == self.reading.groups.len - 1) {
            // Only add if we are not ignoring damaged cells behind the last placed group
            if (behindLast == self.reading.length() or
                !util.contains_(State, self.reading.line[behindLast..], State.Damaged))
            {
                validCounter += 1;
            }
        } else {
            validCounter += self.solveWithCache(behindLast + 1, numPlacedGroups + 1);
        }
    }

    return validCounter;
}

pub fn solve(self: *Solver) u64 {
    return self.solveWithCache(0, 0);
}
