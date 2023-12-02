const std = @import("std");
const util = @import("util");

const Color = enum { red, green, blue };

const Set = struct {
    red: i32,
    green: i32,
    blue: i32,

    fn valid(self: *const Set, reference: Set) bool {
        return self.red <= reference.red and self.green <= reference.green and self.blue <= reference.blue;
    }

    fn power(self: *const Set) i32 {
        return self.red * self.green * self.blue;
    }
};

fn Game() type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        id: i32,
        samples: std.ArrayList(Set),

        pub fn init(id: i32, allocator_: std.mem.Allocator) Self {
            return Self{ .allocator = allocator_, .id = id, .samples = std.ArrayList(Set).init(allocator_) };
        }

        pub fn deinit(self: *Self) void {
            self.samples.deinit();
        }

        pub fn addSample(self: *Self, record: []const u8) void {
            var it = std.mem.split(u8, record, ", ");
            var red: i32 = 0;
            var green: i32 = 0;
            var blue: i32 = 0;
            while (it.next()) |str| {
                var itCube = std.mem.split(u8, str, " ");
                const num = std.fmt.parseInt(i32, itCube.next().?, 10) catch -1;
                const color = itCube.next().?;

                if (std.mem.eql(u8, color, @tagName(Color.red))) {
                    red = num;
                } else if (std.mem.eql(u8, color, @tagName(Color.green))) {
                    green = num;
                } else {
                    blue = num;
                }
            }
            self.samples.append(Set{ .red = red, .green = green, .blue = blue }) catch unreachable;
        }

        pub fn valid(self: *const Self, reference: Set) bool {
            for (self.samples.items) |sample| {
                if (!sample.valid(reference)) {
                    return false;
                }
            }

            return true;
        }

        pub fn minimumViableCubes(self: *const Self) Set {
            var ret = Set{ .red = 0, .green = 0, .blue = 0 };
            for (self.samples.items) |sample| {
                ret.red = @max(ret.red, sample.red);
                ret.green = @max(ret.green, sample.green);
                ret.blue = @max(ret.blue, sample.blue);
            }
            return ret;
        }
    };
}

fn initGames(input: [][]const u8, allocator: std.mem.Allocator) std.ArrayList(Game()) {
    var games = std.ArrayList(Game()).init(allocator);

    for (input) |line| {
        var it = std.mem.split(u8, line, ": ");
        const identifier = it.next().?;
        const records = it.next().?;

        var itIdentifier = std.mem.split(u8, identifier, " ");
        _ = itIdentifier.next(); // Skip Game

        const id = std.fmt.parseInt(i32, itIdentifier.next().?, 10) catch -1;
        var game = Game().init(id, allocator);

        var itRecords = std.mem.split(u8, records, "; ");
        while (itRecords.next()) |record| {
            game.addSample(record);
        }

        games.append(game) catch unreachable;
    }

    return games;
}

pub fn task_01(games: std.ArrayList(Game())) i32 {
    const reference = Set{ .red = 12, .green = 13, .blue = 14 };
    var acc: i32 = 0;

    for (games.items) |game| {
        if (game.valid(reference)) {
            acc += game.id;
        }
    }

    return acc;
}

pub fn task_02(games: std.ArrayList(Game())) i32 {
    var acc: i32 = 0;

    for (games.items) |game| {
        acc += game.minimumViableCubes().power();
    }

    return acc;
}

test "sample results" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_02.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var games = initGames(input, allocator);
    defer games.deinit();
    defer for (games.items) |game| game.samples.deinit();

    try std.testing.expectEqual(@as(i32, 8), task_01(games));
    try std.testing.expectEqual(@as(i32, 2286), task_02(games));
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

    var games = initGames(input, allocator);
    defer games.deinit();
    defer for (games.items) |game| game.samples.deinit(); // TODO: Iterate over nonconst and directly call game.deinit()

    std.debug.print("Day 02 Solution 1: {}\n", .{task_01(games)});
    std.debug.print("Day 02 Solution 2: {}\n", .{task_02(games)});
}
