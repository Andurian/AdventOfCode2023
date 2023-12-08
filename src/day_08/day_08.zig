const std = @import("std");
const util = @import("util");

const TurnDirection = enum(usize) {
    Left = 0,
    Right,

    pub fn fromChar(c: u8) TurnDirection {
        inline for (@typeInfo(TurnDirection).Enum.fields) |f| {
            if (f.name[0] == c) {
                return @enumFromInt(f.value);
            }
        }
        unreachable;
    }
};

const Map = struct {
    instructions: []TurnDirection,
    map: std.AutoHashMap([3]u8, [2][3]u8),
    allocator: std.mem.Allocator,

    pub fn parse(input: [][]const u8, allocator: std.mem.Allocator) Map {
        var instructions = allocator.alloc(TurnDirection, input[0].len) catch unreachable;
        for (input[0], 0..) |c, i| {
            instructions[i] = TurnDirection.fromChar(c);
        }

        var map = std.AutoHashMap([3]u8, [2][3]u8).init(allocator);
        for (input[2..]) |line| {
            var it = std.mem.tokenize(u8, line, " =(,)");
            var start: [3]u8 = undefined;
            @memcpy(&start, it.next().?);

            var left: [3]u8 = undefined;
            @memcpy(&left, it.next().?);

            var right: [3]u8 = undefined;
            @memcpy(&right, it.next().?);

            map.put(start, [2][3]u8{ left, right }) catch unreachable;
        }

        return .{
            .instructions = instructions, //
            .map = map, //
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Map) void {
        self.allocator.free(self.instructions);
        self.map.deinit();
    }

    pub fn findPath(self: Map, start: [3]u8, target: [3]u8) u64 {
        var acc: u64 = 0;
        var i: usize = 0;
        var current = start;
        while (!std.meta.eql(current, target)) {
            const turn = self.instructions[i];
            current = self.map.get(current).?[@intFromEnum(turn)];
            acc += 1;
            if (i >= self.instructions.len - 1) {
                i = 0;
            } else {
                i += 1;
            }
        }
        return acc;
    }

    fn finishedCycles(items: []i32) bool {
        for (items) |item| {
            if (item == -1) {
                return false;
            }
        }
        return true;
    }

    pub fn findMultiPath(self: Map, start: u8, target: u8) u64 {
        var acc: i32 = 0;
        var i: usize = 0;

        var current = std.ArrayList([3]u8).init(self.allocator);
        defer current.deinit();

        var cycleLength = std.ArrayList(i32).init(self.allocator);
        defer cycleLength.deinit();

        var it = self.map.iterator();
        while (it.next()) |entry| {
            if (entry.key_ptr.*[2] == start) {
                var x: [3]u8 = undefined;
                @memcpy(&x, entry.key_ptr);
                current.append(x) catch unreachable;
                cycleLength.append(-1) catch unreachable;
            }
        }

        while (!finishedCycles(cycleLength.items)) {
            const turn = self.instructions[i];
            acc += 1;

            var j: usize = 0;
            while (j < current.items.len) : (j += 1) {
                current.items[j] = self.map.get(current.items[j]).?[@intFromEnum(turn)];
                if (current.items[j][2] == target and cycleLength.items[j] == -1) {
                    cycleLength.items[j] = acc;
                }
            }

            if (i >= self.instructions.len - 1) {
                i = 0;
            } else {
                i += 1;
            }
        }

        var res: u64 = util.lcm(@as(u64, @intCast(cycleLength.items[0])), @as(u64, @intCast(cycleLength.items[1])));
        var j: usize = 2;
        while (j < cycleLength.items.len) : (j += 1) {
            res = util.lcm(res, @as(u64, @intCast(cycleLength.items[j])));
        }

        return res;
    }
};

pub fn task_01(map: Map) u64 {
    return map.findPath([3]u8{ 'A', 'A', 'A' }, [3]u8{ 'Z', 'Z', 'Z' });
}

pub fn task_02(map: Map) u64 {
    return map.findMultiPath('A', 'Z');
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

    var map = Map.parse(input, allocator);
    defer map.deinit();

    std.debug.print("Day 08 Solution 1: {}\n", .{task_01(map)});
    std.debug.print("Day 07 Solution 2: {}\n", .{task_02(map)});
}
