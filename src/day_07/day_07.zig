const std = @import("std");
const util = @import("util");

const CardType = enum(u32) {
    C2 = 0,
    C3,
    C4,
    C5,
    C6,
    C7,
    C8,
    C9,
    CT,
    CJ,
    CQ,
    CK,
    CA,

    pub fn fromChar(c: u8) CardType {
        // char 'X' maps to CardType.CX
        inline for (@typeInfo(CardType).Enum.fields) |f| {
            if (f.name[1] == c) {
                return @enumFromInt(f.value);
            }
        }
        unreachable;
    }

    pub fn lt(lhs: CardType, rhs: CardType) bool {
        return @intFromEnum(lhs) < @intFromEnum(rhs);
    }

    pub fn ltWithJoker(lhs: CardType, rhs: CardType) bool {
        var lhsV: i32 = @intCast(@intFromEnum(lhs));
        var rhsV: i32 = @intCast(@intFromEnum(rhs));

        if (lhs == CardType.CJ) lhsV = -1;
        if (rhs == CardType.CJ) rhsV = -1;

        return lhsV < rhsV;
    }
};

pub fn cardsFromStr(str: []const u8) [5]CardType {
    var ret: [5]CardType = undefined;
    for (str, 0..) |c, i| {
        ret[i] = CardType.fromChar(c);
    }
    return ret;
}

const HandType = enum(i32) {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOAK,
    FullHouse,
    FourOAK,
    FiveOAK,
};

pub fn handType(hand: [5]CardType) HandType {
    var hist = [_]u32{0} ** @typeInfo(CardType).Enum.fields.len;
    for (hand) |card| {
        hist[@intFromEnum(card)] += 1;
    }

    const max = util.max2(u32, &hist);

    if (max[0] == 5) return HandType.FiveOAK;
    if (max[0] == 4) return HandType.FourOAK;
    if (max[0] == 3) {
        if (max[1] == 2) return HandType.FullHouse;
        return HandType.ThreeOAK;
    }
    if (max[0] == 2) {
        if (max[1] == 2) return HandType.TwoPair;
        return HandType.OnePair;
    }
    return HandType.HighCard;
}

pub fn handTypeWithJoker(hand: [5]CardType) HandType {
    var hist = [_]u32{0} ** @typeInfo(CardType).Enum.fields.len;
    var numJoker: u32 = 0;
    for (hand) |card| {
        if (card == CardType.CJ) {
            numJoker += 1;
        } else {
            hist[@intFromEnum(card)] += 1;
        }
    }

    const max = util.max2(u32, &hist);

    if (max[0] + numJoker == 5) return HandType.FiveOAK;
    if (max[0] + numJoker == 4) return HandType.FourOAK;
    if (max[0] + numJoker == 3) {
        if (max[1] == 2) return HandType.FullHouse; // If we have more than one joker it's always possible to make something better than a FullHouse
        return HandType.ThreeOAK;
    }
    if (max[0] + numJoker == 2) {
        if (max[1] == 2) return HandType.TwoPair;
        return HandType.OnePair;
    }
    return HandType.HighCard;
}

test handType {
    try std.testing.expectEqual(HandType.FiveOAK, handType(cardsFromStr("55555")));
    try std.testing.expectEqual(HandType.FourOAK, handType(cardsFromStr("33332")));
    try std.testing.expectEqual(HandType.FourOAK, handType(cardsFromStr("2AAAA")));
    try std.testing.expectEqual(HandType.FullHouse, handType(cardsFromStr("77888")));
    try std.testing.expectEqual(HandType.FullHouse, handType(cardsFromStr("77788")));
    try std.testing.expectEqual(HandType.OnePair, handType(cardsFromStr("32T3K")));
    try std.testing.expectEqual(HandType.TwoPair, handType(cardsFromStr("KK677")));
    try std.testing.expectEqual(HandType.TwoPair, handType(cardsFromStr("KTJJT")));
    try std.testing.expectEqual(HandType.ThreeOAK, handType(cardsFromStr("T55J5")));
    try std.testing.expectEqual(HandType.ThreeOAK, handType(cardsFromStr("QQQJA")));
}

const SortContext = struct {
    getHandType: *const fn ([5]CardType) HandType, //
    lt: *const fn (CardType, CardType) bool,
};

const Hand = struct {
    cards: [5]CardType,
    bid: i32,

    pub fn lt(context: SortContext, lhs: Hand, rhs: Hand) bool {
        const lhsType = context.getHandType(lhs.cards);
        const rhsType = context.getHandType(rhs.cards);

        if (lhsType == rhsType) {
            var i: usize = 0;
            while (i < lhs.cards.len) : (i += 1) {
                if (lhs.cards[i] == rhs.cards[i]) continue;
                return context.lt(lhs.cards[i], rhs.cards[i]);
            }

            return false;
        }

        return @intFromEnum(lhsType) < @intFromEnum(rhsType);
    }
};

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) []Hand {
    var ret = std.ArrayList(Hand).init(allocator);
    defer ret.deinit();

    for (input) |line| {
        var it = std.mem.tokenize(u8, line, " ");

        const cards = cardsFromStr(it.next().?);
        const bid = std.fmt.parseInt(i32, it.next().?, 10) catch unreachable;
        ret.append(.{ .cards = cards, .bid = bid }) catch unreachable;
    }

    return ret.toOwnedSlice() catch unreachable;
}

pub fn accumulate(hands: []Hand, context: SortContext) i32 {
    std.mem.sort(Hand, hands, context, Hand.lt);

    var acc: i32 = 0;
    for (hands, 0..) |hand, i| {
        const ii: i32 = @intCast(i + 1);
        acc += hand.bid * ii;
    }

    return acc;
}

pub fn task_01(hands: []Hand) i32 {
    return accumulate(hands, .{ .getHandType = &handType, .lt = &CardType.lt });
}

pub fn task_02(hands: []Hand) i32 {
    return accumulate(hands, .{ .getHandType = &handTypeWithJoker, .lt = &CardType.ltWithJoker });
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_07.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var hands = parseInput(input, allocator);
    defer allocator.free(hands);

    try std.testing.expectEqual(@as(i32, 6440), task_01(hands));
    try std.testing.expectEqual(@as(i32, 5905), task_02(hands));
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

    var hands = parseInput(input, allocator);
    defer allocator.free(hands);

    std.debug.print("Day 07 Solution 1: {}\n", .{task_01(hands)});
    std.debug.print("Day 07 Solution 2: {}\n", .{task_02(hands)});
}
