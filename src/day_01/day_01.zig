const std = @import("std");
const util = @import("util");

fn parse(str: []const u8) i32 {
    var acc: i32 = 0;

    var i: @TypeOf(str.len) = 0;
    while (i < str.len) : (i += 1) {
        switch (str[i]) {
            '0'...'9' => {
                acc += 10 * (std.fmt.parseInt(i32, str[i .. i + 1], 10) catch unreachable);
                break;
            },
            else => {},
        }
    }

    i = str.len - 1;
    while (i >= 0) : (i -= 1) {
        switch (str[i]) {
            '0'...'9' => {
                acc += std.fmt.parseInt(i32, str[i .. i + 1], 10) catch unreachable;
                break;
            },
            else => {},
        }
    }

    return acc;
}

test parse {
    try std.testing.expectEqual(@as(i32, 12), parse("1abc2"));
    try std.testing.expectEqual(@as(i32, 38), parse("pqr3stu8vwx"));
    try std.testing.expectEqual(@as(i32, 15), parse("a1b2c3d4e5f"));
    try std.testing.expectEqual(@as(i32, 77), parse("treb7uchet"));
}

fn replacementPossible(str: []const u8, pattern: []const u8) bool {
    if (pattern.len > str.len) {
        return false;
    }
    return std.mem.eql(u8, str[0..pattern.len], pattern);
}

const Number = enum { zero, one, two, three, four, five, six, seven, eight, nine };

fn normalize(str: []u8) void {
    const numbers = [_]Number{ .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine };
    outer: for (str, 0..) |_, i| {
        for (numbers) |number| {
            if (replacementPossible(str[i..], @tagName(number))) {
                str[i] = @as(u8, 48) + @intFromEnum(number);
                continue :outer;
            }
        }
    }
}

test normalize {
    var s1 = [_]u8{ 't', 'w', 'o', '1', 'n', 'i', 'n', 'e' };
    normalize(&s1);
    try std.testing.expectEqualStrings("2wo19ine", &s1);
}

fn task_01(items: [][]const u8) i32 {
    var acc: i32 = 0;
    for (items) |item| {
        acc += parse(item);
    }
    return acc;
}

test task_01 {
    var items = [_][]const u8{ "1abc2", "pqr3stu8vwx", "a1b2c3d4e5f", "treb7uchet" };
    try std.testing.expect(142 == task_01(&items));
}

fn task_02(items: [][]u8) i32 {
    var acc: i32 = 0;
    for (items, 0..) |_, i| {
        normalize(items[i]);
        acc += parse(items[i]);
    }
    return acc;
}

test task_02 {
    // TODO: Create mutable testing data
    // var items = [_][]const u8{ "two1nine", "eightwothree", "abcone2threexyz", "xtwone3four", "4nineeightseven2", "zoneight234", "7pqrstsixteen" };
    // std.debug.print("{}\n", .{task_02(&items)});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile(args[1], allocator);
    defer allocator.free(input);

    std.debug.print("Day 01 Solution 1: {}\n", .{task_01(input)});
    std.debug.print("Day 02 Solution 2: {}\n", .{task_02(input)});

    for (input) |i| allocator.free(i);
}
