const std = @import("std");
const util = @import("util");

const Race = struct {
    time: i64,
    record: i64,
    timeF: f64,
    recordF: f64,

    pub fn init(time_: i64, record_: i64) Race {
        return .{
            .time = time_, //
            .record = record_, //
            .timeF = @floatFromInt(time_), //
            .recordF = @floatFromInt(record_),
        };
    }

    pub fn distance(self: Race, t: i64) i64 {
        return t * (self.time - t);
    }

    pub fn winRange(self: Race) [2]i64 {
        // solve x^2 - timeF*x + recordF = 0
        const t2 = 0.5 * self.timeF;
        const y = std.math.sqrt(t2 * t2 - self.recordF);

        var min: i64 = @intFromFloat(@ceil(t2 - y));
        var max: i64 = @intFromFloat(@floor(t2 + y));

        // correct if an exact solution is hit
        if (self.distance(min) == self.record) min += 1;
        if (self.distance(max) == self.record) max -= 1;

        return [_]i64{ min, max };
    }

    pub fn waysToWin(self: Race) i64 {
        const range = self.winRange();
        return range[1] - range[0] + 1;
    }
};

test "Ways To Win" {
    const r1 = Race.init(7, 9);
    const r2 = Race.init(15, 40);
    const r3 = Race.init(30, 200);

    try std.testing.expectEqual([2]i64{ 2, 5 }, r1.winRange());
    try std.testing.expectEqual([2]i64{ 4, 11 }, r2.winRange());
    try std.testing.expectEqual([2]i64{ 11, 19 }, r3.winRange());
}

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Race {
    var ret = std.ArrayList(Race).init(allocator);
    defer ret.deinit();

    var itTime = std.mem.tokenize(u8, input[0], ": ");
    var itRecord = std.mem.tokenize(u8, input[1], ": ");

    _ = itTime.next(); // skip "Time"
    _ = itRecord.next(); // skip "Record"

    while (itTime.next()) |timeStr| {
        const recordStr = itRecord.next().?;
        const time = std.fmt.parseInt(i64, timeStr, 10) catch unreachable;
        const record = std.fmt.parseInt(i64, recordStr, 10) catch unreachable;
        ret.append(Race.init(time, record)) catch unreachable;
    }

    return ret.toOwnedSlice() catch unreachable;
}

pub fn parseInputWithoutKerning(input: [][]const u8, allocator: std.mem.Allocator) Race {
    var timeStrAcc = std.ArrayList(u8).init(allocator);
    defer timeStrAcc.deinit();

    var recordStrAcc = std.ArrayList(u8).init(allocator);
    defer recordStrAcc.deinit();

    var itTime = std.mem.tokenize(u8, input[0], ": ");
    var itRecord = std.mem.tokenize(u8, input[1], ": ");

    _ = itTime.next(); // skip "Time"
    _ = itRecord.next(); // skip "Record"

    while (itTime.next()) |timeStr| {
        const recordStr = itRecord.next().?;

        timeStrAcc.appendSlice(timeStr) catch unreachable;
        recordStrAcc.appendSlice(recordStr) catch unreachable;
    }

    const time = std.fmt.parseInt(i64, timeStrAcc.items, 10) catch unreachable;
    const record = std.fmt.parseInt(i64, recordStrAcc.items, 10) catch unreachable;

    return Race.init(time, record);
}

pub fn task_01(races: []Race) i64 {
    var acc: i64 = 1;
    for (races) |race| {
        acc *= race.waysToWin();
    }
    return acc;
}

pub fn task_02(race: Race) i64 {
    return race.waysToWin();
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile("input/test/day_06.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    const races = parseInput(input, allocator);
    defer allocator.free(races);

    const singleRace = parseInputWithoutKerning(input, allocator);

    try std.testing.expectEqual(@as(i64, 288), task_01(races));
    try std.testing.expectEqual(@as(i64, 71503), task_02(singleRace));
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

    const races = parseInput(input, allocator);
    defer allocator.free(races);

    const singleRace = parseInputWithoutKerning(input, allocator);

    std.debug.print("Day 06 Solution 1: {}\n", .{task_01(races)});
    std.debug.print("Day 06 Solution 2: {}\n", .{task_02(singleRace)});
}
