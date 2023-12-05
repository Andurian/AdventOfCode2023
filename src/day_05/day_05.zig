const std = @import("std");
const util = @import("util");

const InputRange = struct {
    start: i64,
    length: i64,
    pub fn last(self: InputRange) i64 {
        return self.start + self.length - 1;
    }

    pub fn end(self: InputRange) i64 {
        return self.start + self.length;
    }
};

fn inputRangeLt(_: void, lhs: InputRange, rhs: InputRange) bool {
    return lhs.start < rhs.start;
}

const Range = struct {
    sourceStart: i64,
    destinationStart: i64,
    length: i64,

    pub fn fromString(str: []const u8) !Range {
        var it = std.mem.tokenize(u8, str, " ");
        var curr = it.next().?;
        const destinationStart = try std.fmt.parseInt(i64, curr, 10);
        curr = it.next().?;
        const sourceStart = try std.fmt.parseInt(i64, curr, 10);
        curr = it.next().?;
        const length = try std.fmt.parseInt(i64, curr, 10);
        return Range{
            .sourceStart = sourceStart, //
            .destinationStart = destinationStart, //
            .length = length, //
        };
    }

    pub fn canMap(self: Range, input: i64) bool {
        return input >= self.sourceStart and input < self.sourceStart + self.length;
    }

    pub fn map(self: Range, input: i64) i64 {
        if (self.canMap(input)) {
            const diff = input - self.sourceStart;
            return self.destinationStart + diff;
        }
        return input;
    }
};

fn lt(_: void, lhs: Range, rhs: Range) bool {
    return lhs.sourceStart < rhs.sourceStart;
}

const Mapping = struct {
    sourceType: []u8,
    destinationType: []u8,
    sourceBreakingPoints: []i64,
    ranges: []Range,
    allocator: std.mem.Allocator,

    pub fn initFromInput(lines: [][]u8, allocator: std.mem.Allocator) Mapping {
        var it = std.mem.tokenize(u8, lines[0], "- ");
        const sourceTypeSrc = it.next().?;
        _ = it.next().?; // skip "to"
        const destinationTypeSrc = it.next().?;

        var sourceType = allocator.alloc(u8, sourceTypeSrc.len) catch unreachable;
        std.mem.copy(u8, sourceType, sourceTypeSrc);

        var destinationType = allocator.alloc(u8, destinationTypeSrc.len) catch unreachable;
        std.mem.copy(u8, destinationType, destinationTypeSrc);

        var ranges = std.ArrayList(Range).init(allocator);
        defer ranges.deinit();

        for (lines[1..]) |line| {
            const range = Range.fromString(line) catch unreachable;
            ranges.append(range) catch unreachable;
        }

        std.mem.sort(Range, ranges.items, {}, comptime lt);

        var sourceBreakingPoints = std.ArrayList(i64).init(allocator);
        defer sourceBreakingPoints.deinit();

        for (ranges.items) |range| {
            util.appendIfNotContains(i64, &sourceBreakingPoints, range.sourceStart);
            util.appendIfNotContains(i64, &sourceBreakingPoints, range.sourceStart + range.length);
        }

        return Mapping{
            .sourceType = sourceType, //
            .destinationType = destinationType, //
            .sourceBreakingPoints = sourceBreakingPoints.toOwnedSlice() catch unreachable, //
            .ranges = ranges.toOwnedSlice() catch unreachable, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Mapping) void {
        self.allocator.free(self.sourceType);
        self.allocator.free(self.destinationType);
        self.allocator.free(self.sourceBreakingPoints);
        self.allocator.free(self.ranges);
    }

    pub fn map(self: Mapping, input: i64) i64 {
        for (self.ranges) |range| {
            if (range.canMap(input)) {
                return range.map(input);
            }
        }
        return input;
    }

    pub fn mapRange(self: Mapping, inputRange: InputRange) std.ArrayList(InputRange) {
        var splitInputRanges = std.ArrayList(InputRange).init(self.allocator);
        defer splitInputRanges.deinit();

        var currentStart = inputRange.start;
        for (self.sourceBreakingPoints) |p| {
            if (p > currentStart and p < inputRange.end()) {
                const newRange = InputRange{ .start = currentStart, .length = p - currentStart };
                splitInputRanges.append(newRange) catch unreachable;
                currentStart = p;
            }
        }
        const newRange = InputRange{ .start = currentStart, .length = inputRange.end() - currentStart };
        splitInputRanges.append(newRange) catch unreachable;

        var ret = std.ArrayList(InputRange).init(self.allocator);

        for (splitInputRanges.items) |range| {
            const mappedRange = InputRange{ .start = self.map(range.start), .length = range.length };
            ret.append(mappedRange) catch unreachable;
        }

        return ret;
    }
};

const Pipeline = struct {
    mappings: []Mapping,
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]u8, allocator: std.mem.Allocator) Pipeline {
        var start: usize = 0;
        var end: usize = 0;

        var mappings = std.ArrayList(Mapping).init(allocator);
        defer mappings.deinit();

        while (start < input.len) {
            for (input[start..], start..) |line, i| {
                if (line.len == 0) {
                    end = i;
                    break;
                }
            }

            if (end < start) {
                end = input.len - 1;
            }

            mappings.append(Mapping.initFromInput(input[start..end], allocator)) catch unreachable;
            start = end + 1;
        }

        return Pipeline{
            .mappings = mappings.toOwnedSlice() catch unreachable,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Pipeline) void {
        for (self.mappings) |*mapping| {
            mapping.deinit();
        }
        self.allocator.free(self.mappings);
    }

    pub fn map(self: Pipeline, input_: i64, inputType_: []const u8) i64 {
        var input = input_;
        var inputType = inputType_;

        var conversionDone = true;
        while (conversionDone) {
            conversionDone = false;
            for (self.mappings) |mapping| {
                if (std.mem.eql(u8, mapping.sourceType, inputType)) {
                    input = mapping.map(input);
                    inputType = mapping.destinationType;
                    conversionDone = true;
                    break;
                }
            }
        }
        return input;
    }

    pub fn mapRange(self: Pipeline, input_: std.ArrayList(InputRange), inputType_: []const u8) std.ArrayList(InputRange) {
        var inputType = inputType_;

        var input = std.ArrayList(InputRange).init(self.allocator);
        var results = std.ArrayList(InputRange).init(self.allocator);
        defer results.deinit();

        input.appendSlice(input_.items) catch unreachable;

        var conversionDone = true;
        while (conversionDone) {
            conversionDone = false;
            for (self.mappings) |mapping| {
                if (std.mem.eql(u8, mapping.sourceType, inputType)) {
                    for (input.items) |i| {
                        var res = mapping.mapRange(i);
                        defer res.deinit();

                        results.appendSlice(res.items) catch unreachable;
                    }
                    inputType = mapping.destinationType;
                    conversionDone = true;
                    break;
                }
            }

            if (conversionDone) {
                input.clearRetainingCapacity();
                input.appendSlice(results.items) catch unreachable;
                results.clearRetainingCapacity();
            }
        }

        return input;
    }
};

pub fn task_01(pipeline: Pipeline, seeds: []const i64) i64 {
    var min = pipeline.map(seeds[0], "seed");
    if (seeds.len > 1) {
        for (seeds) |seed| {
            const result = pipeline.map(seed, "seed");
            min = @min(min, result);
        }
    }
    return min;
}

pub fn task_02(pipeline: Pipeline, seeds: []const i64) i64 {
    var min = pipeline.map(seeds[0], "seed");

    var i: usize = 0;
    while (i < seeds.len) : (i += 2) {
        const start = seeds[i];
        const range = seeds[i + 1];

        var seed = start;
        while (seed < start + range) : (seed += 1) {
            const result = pipeline.map(seed, "seed");
            min = @min(min, result);
        }
    }

    return min;
}

pub fn task_02_smart(pipeline: Pipeline, seeds: []const i64, allocator: std.mem.Allocator) i64 {
    var inputRanges = std.ArrayList(InputRange).init(allocator);
    defer inputRanges.deinit();

    var i: usize = 0;
    while (i < seeds.len) : (i += 2) {
        const start = seeds[i];
        const length = seeds[i + 1];

        inputRanges.append(.{ .start = start, .length = length }) catch unreachable;
    }

    var result = pipeline.mapRange(inputRanges, "seed");
    defer result.deinit();

    var min: i64 = std.math.maxInt(i64);
    for (result.items) |it| {
        min = @min(min, it.start);
    }

    return min;
}

test "test input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile("input/test/day_05.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var pipeline = Pipeline.initFromInput(input[2..], allocator);
    defer pipeline.deinit();

    try std.testing.expectEqual(@as(i64, 82), pipeline.map(79, "seed"));
    try std.testing.expectEqual(@as(i64, 43), pipeline.map(14, "seed"));
    try std.testing.expectEqual(@as(i64, 86), pipeline.map(55, "seed"));
    try std.testing.expectEqual(@as(i64, 35), pipeline.map(13, "seed"));

    const seeds = [_]i64{ 79, 14, 55, 13 };
    const minLocation = task_01(pipeline, &seeds);

    try std.testing.expectEqual(@as(i64, 35), minLocation);

    const minLocation2 = task_02(pipeline, &seeds);
    try std.testing.expectEqual(@as(i64, 46), minLocation2);

    const minLocation3 = task_02_smart(pipeline, &seeds, allocator);
    try std.testing.expectEqual(@as(i64, 46), minLocation3);
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

    var pipeline = Pipeline.initFromInput(input[2..], allocator);
    defer pipeline.deinit();

    var seeds = std.ArrayList(i64).init(allocator);
    defer seeds.deinit();

    var it = std.mem.tokenize(u8, input[0], " ");
    _ = it.next().?; // skip "seeds:"
    while (it.next()) |token| {
        const seed = std.fmt.parseInt(i64, token, 10) catch unreachable;
        seeds.append(seed) catch unreachable;
    }

    std.debug.print("Day 05 Solution 1: {}\n", .{task_01(pipeline, seeds.items)});
    std.debug.print("Day 05 Solution 2: {}\n", .{task_02_smart(pipeline, seeds.items, allocator)});
}
