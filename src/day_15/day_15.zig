const std = @import("std");
const util = @import("util");

const Lens = struct {
    label: []const u8,
    focalLength: ?u64,
    hash: u64,

    pub fn print(self: Lens) void {
        util.print("[{s} {any}]", .{ self.label, self.focalLength });
    }
};

const Instruction = struct {
    const Operation = enum { Add, Remove };

    lens: Lens,
    op: Operation,

    pub fn fromString(str: []const u8) Instruction {
        if (str[str.len - 1] == '-') {
            const label = str[0 .. str.len - 1];
            return .{ .lens = .{ .label = label, .focalLength = null, .hash = hash(label) }, .op = Operation.Remove };
        } else {
            const label = str[0 .. str.len - 2];
            const focalLength = std.fmt.parseInt(u64, str[str.len - 1 ..], 10) catch unreachable;
            return .{ .lens = .{ .label = label, .focalLength = focalLength, .hash = hash(label) }, .op = Operation.Add };
        }
    }
};

const HASHMAP = struct {
    boxes: [256]std.TailQueue(Lens),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HASHMAP {
        return .{ .boxes = [_]std.TailQueue(Lens){.{}} ** 256, .allocator = allocator };
    }

    pub fn deinit(self: *HASHMAP) void {
        for (&self.boxes) |*b| {
            var node = b.first;
            while (node != null) { // For some reason popFront leads to invalid free?
                b.remove(node.?);
                self.allocator.destroy(node.?);
                node = b.first;
            }
        }
    }

    pub fn perform(self: *HASHMAP, instruction: Instruction) void {
        switch (instruction.op) {
            Instruction.Operation.Remove => self.remove(instruction.lens),
            Instruction.Operation.Add => self.add(instruction.lens),
        }
    }

    pub fn add(self: *HASHMAP, lens: Lens) void {
        var newNode = self.allocator.create(std.TailQueue(Lens).Node) catch unreachable;
        newNode.* = .{ .data = lens };
        var box = &self.boxes[lens.hash];
        var node = find(box.first, lens.label);
        if (node != null) {
            var prev = node.?.prev;
            box.remove(node.?);
            self.allocator.destroy(node.?);
            if (prev) |before| {
                box.insertAfter(before, newNode);
            } else {
                box.prepend(newNode);
            }
        } else {
            box.append(newNode);
        }
    }

    pub fn remove(self: *HASHMAP, lens: Lens) void {
        var box = &self.boxes[lens.hash];
        var node = find(box.first, lens.label);
        if (node != null) {
            box.remove(node.?);
            self.allocator.destroy(node.?);
        }
    }

    fn find(start: ?*std.TailQueue(Lens).Node, label: []const u8) ?*std.TailQueue(Lens).Node {
        if (start == null) return null;
        var node = start.?;
        while (!std.mem.eql(u8, node.data.label, label)) {
            if (node.next == null) return null;
            node = node.next.?;
        }
        return node;
    }

    pub fn print(self: HASHMAP) void {
        for (&self.boxes, 0..) |*box, i| {
            if (box.first == null) continue;
            util.print("Box {}: ", .{i});
            var node = box.first;
            while (node != null) : (node = node.?.next) {
                node.?.data.print();
            }
            util.print("\n", .{});
        }
    }

    pub fn focusingPower(self: HASHMAP) u64 {
        var acc: u64 = 0;
        for (&self.boxes, 1..) |*box, i| {
            var j: u64 = 1;
            var node = box.first;
            while (node != null) {
                const v = i * j * node.?.data.focalLength.?;
                acc += v;
                j += 1;
                node = node.?.next;
            }
        }
        return acc;
    }
};

pub fn hash(str: []const u8) u64 {
    var acc: u64 = 0;
    for (str) |c| {
        acc += @as(u64, @intCast(c));
        acc *= 17;
        acc %= 256;
    }
    return acc;
}

test hash {
    try std.testing.expectEqual(@as(u64, 52), hash("HASH"));
}

pub fn task_01(str: []const u8) u64 {
    var it = std.mem.tokenize(u8, str, ",");
    var acc: u64 = 0;
    while (it.next()) |token| {
        acc += hash(token);
    }
    return acc;
}

pub fn task_02(str: []const u8, allocator: std.mem.Allocator) u64 {
    var map = HASHMAP.init(allocator);
    defer map.deinit();

    var it = std.mem.tokenize(u8, str, ",");
    while (it.next()) |token| {
        //util.print("{s}\n", .{token});
        map.perform(Instruction.fromString(token));
        //map.print();
        //util.print("\n\n", .{});
    }

    return map.focusingPower();
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_15.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    try std.testing.expectEqual(@as(u64, 1320), task_01(input[0]));
    try std.testing.expectEqual(@as(u64, 145), task_02(input[0], allocator));
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

    std.debug.print("Day 15 Solution 1: {}\n", .{task_01(input[0])});
    std.debug.print("Day 15 Solution 2: {}\n", .{task_02(input[0], allocator)});
}
