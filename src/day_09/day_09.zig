const std = @import("std");
const util = @import("util");

pub fn initDerivative(numbers: []i32, allocator: std.mem.Allocator) []i32 {
    var derivative = std.ArrayList(i32).init(allocator);
    defer derivative.deinit();

    var i: usize = 1;
    while (i < numbers.len) : (i += 1) {
        derivative.append(numbers[i] - numbers[i - 1]) catch unreachable;
    }

    return derivative.toOwnedSlice() catch unreachable;
}

pub fn findNext_(numbers: []i32, allocator: std.mem.Allocator) i32 {
    if (util.allEqual(i32, 0, numbers)) return 0;

    var derivative = initDerivative(numbers, allocator);
    defer allocator.free(derivative);

    return findNext_(derivative, allocator) + numbers[numbers.len - 1];
}

pub fn findPrevious_(numbers: []i32, allocator: std.mem.Allocator) i32 {
    if (util.allEqual(i32, 0, numbers)) return 0;

    var derivative = initDerivative(numbers, allocator);
    defer allocator.free(derivative);

    return numbers[0] - findPrevious_(derivative, allocator);
}

const Sequence = struct {
    numbers: std.ArrayList(i32),
    allocator: std.mem.Allocator,

    pub fn init(str: []u8, allocator: std.mem.Allocator) Sequence {
        var nums = std.ArrayList(i32).init(allocator);

        var it = std.mem.tokenize(u8, str, " ");
        while (it.next()) |token| {
            const n = std.fmt.parseInt(i32, token, 10) catch unreachable;
            nums.append(n) catch unreachable;
        }

        return .{
            .numbers = nums, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Sequence) void {
        self.numbers.deinit();
    }

    pub fn findNext(self: Sequence) i32 {
        return findNext_(self.numbers.items, self.allocator);
    }

    pub fn findPrevious(self: Sequence) i32 {
        return findPrevious_(self.numbers.items, self.allocator);
    }
};

pub fn parseInput(input: [][]u8, allocator: std.mem.Allocator) []Sequence {
    var sequences = std.ArrayList(Sequence).init(allocator);
    defer sequences.deinit();

    for (input) |line| {
        sequences.append(Sequence.init(line, allocator)) catch unreachable;
    }

    return sequences.toOwnedSlice() catch unreachable;
}

pub fn task_01(sequences: []Sequence) i32 {
    var acc: i32 = 0;
    for (sequences) |s| acc += s.findNext();
    return acc;
}

pub fn task_02(sequences: []Sequence) i32 {
    var acc: i32 = 0;
    for (sequences) |s| acc += s.findPrevious();
    return acc;
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_09.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var sequences = parseInput(input, allocator);
    defer allocator.free(sequences);
    defer for (sequences) |*s| s.deinit();

    try std.testing.expectEqual(@as(i32, 114), task_01(sequences));
    try std.testing.expectEqual(@as(i32, 2), task_02(sequences));
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

    var sequences = parseInput(input, allocator);
    defer allocator.free(sequences);
    defer for (sequences) |*s| s.deinit();

    std.debug.print("Day 09 Solution 1: {}\n", .{task_01(sequences)});
    std.debug.print("Day 09 Solution 2: {}\n", .{task_02(sequences)});
}
