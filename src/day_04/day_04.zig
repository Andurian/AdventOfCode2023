const std = @import("std");
const util = @import("util");

const Card = struct {
    id: i32,
    winningNumbers: []i32,
    yourNumbers: []i32,
    allocator: std.mem.Allocator,

    pub fn initFromString(str: []const u8, allocator: std.mem.Allocator) Card {
        var topLevelTokens = std.mem.tokenize(u8, str, ":|");

        const idStr = topLevelTokens.next() orelse unreachable;
        const winningNumbersStr = topLevelTokens.next() orelse unreachable;
        const yourNumbersStr = topLevelTokens.next() orelse unreachable;

        var idTokens = std.mem.tokenize(u8, idStr, " ");
        _ = idTokens.next(); // Skip over "Card"
        const id = std.fmt.parseInt(i32, idTokens.next() orelse unreachable, 10) catch unreachable;

        var winningNumbers = std.ArrayList(i32).init(allocator);
        defer winningNumbers.deinit();

        var winningNumbersTokens = std.mem.tokenize(u8, winningNumbersStr, " ");
        while (winningNumbersTokens.next()) |token| {
            const num = std.fmt.parseInt(i32, token, 10) catch unreachable;
            winningNumbers.append(num) catch unreachable;
        }

        var yourNumbers = std.ArrayList(i32).init(allocator);
        defer yourNumbers.deinit();

        var yourNumbersTokens = std.mem.tokenize(u8, yourNumbersStr, " ");
        while (yourNumbersTokens.next()) |token| {
            const num = std.fmt.parseInt(i32, token, 10) catch unreachable;
            yourNumbers.append(num) catch unreachable;
        }

        return Card{
            .id = id, //
            .winningNumbers = winningNumbers.toOwnedSlice() catch unreachable, //
            .yourNumbers = yourNumbers.toOwnedSlice() catch unreachable, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Card) void {
        self.allocator.free(self.winningNumbers);
        self.allocator.free(self.yourNumbers);
    }

    pub fn print(self: Card) void {
        util.print("Card {}: {any} | {any}\n", .{ self.id, self.winningNumbers, self.yourNumbers });
    }

    pub fn value(self: Card) i32 {
        var acc: i32 = 0;
        loop: for (self.yourNumbers) |yourNum| {
            for (self.winningNumbers) |winningNum| {
                if (yourNum == winningNum) {
                    if (acc == 0) {
                        acc = 1;
                    } else {
                        acc *= 2;
                    }
                    continue :loop;
                }
            }
        }
        return acc;
    }

    pub fn numMatches(self: Card) i32 {
        var acc: i32 = 0;
        loop: for (self.yourNumbers) |yourNum| {
            for (self.winningNumbers) |winningNum| {
                if (yourNum == winningNum) {
                    acc += 1;
                    continue :loop;
                }
            }
        }
        return acc;
    }
};

pub fn task_01(cards: []const Card) i32 {
    var acc: i32 = 0;
    for (cards) |card| {
        acc += card.value();
    }
    return acc;
}

pub fn task_02(cards: []const Card, allocator: std.mem.Allocator) i32 {
    var copies = allocator.alloc(i32, cards.len) catch unreachable;
    defer allocator.free(copies);

    for (copies) |*c| c.* = 1; // the original copies

    var i: usize = 0;
    while (i < cards.len) : (i += 1) {
        const numWins = cards[i].numMatches();
        var j: usize = 0;
        while (j < numWins) : (j += 1) {
            copies[i + j + 1] += copies[i];
        }
    }

    var acc: i32 = 0;
    for (copies) |c| acc += c;
    return acc;
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile("input/test/day_04.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var cards = std.ArrayList(Card).init(allocator);
    defer cards.deinit();
    defer for (cards.items) |*card| card.deinit();

    for (input) |line| {
        cards.append(Card.initFromString(line, allocator)) catch unreachable;
    }

    try std.testing.expectEqual(@as(i32, 13), task_01(cards.items));
    try std.testing.expectEqual(@as(i32, 30), task_02(cards.items, allocator));
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

    var cards = std.ArrayList(Card).init(allocator);
    defer cards.deinit();
    defer for (cards.items) |*card| card.deinit();

    for (input) |line| {
        cards.append(Card.initFromString(line, allocator)) catch unreachable;
    }

    std.debug.print("Day 04 Solution 1: {}\n", .{task_01(cards.items)});
    std.debug.print("Day 04 Solution 2: {}\n", .{task_02(cards.items, allocator)});
}
