const std = @import("std");
const util = @import("util");

const Point = struct {
    row: i32,
    col: i32,

    pub fn neighbors(self: Point) [8]Point {
        return [8]Point{ //
            .{ .row = self.row - 1, .col = self.col - 1 }, //
            .{ .row = self.row - 1, .col = self.col + 0 }, //
            .{ .row = self.row - 1, .col = self.col + 1 }, //
            .{ .row = self.row + 0, .col = self.col - 1 }, //
            .{ .row = self.row + 0, .col = self.col + 1 }, //
            .{ .row = self.row + 1, .col = self.col - 1 }, //
            .{ .row = self.row + 1, .col = self.col + 0 }, //
            .{ .row = self.row + 1, .col = self.col + 1 }, //
        };
    }
};

const PartNumber = struct {
    number: i32,
    neighborSymbols: std.ArrayList(Point),

    pub fn deinit(self: PartNumber) void {
        self.neighborSymbols.deinit();
    }
};

const Field = struct {
    width: i32,
    height: i32,
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) Field {
        const height = input.len;
        const width = input[0].len;
        const s: usize = width * height;
        var data = allocator.alloc(u8, s) catch unreachable;

        var row: usize = 0;
        while (row < height) : (row += 1) {
            const start = row * width;
            std.mem.copy(u8, data[start..], input[row]);
        }

        return Field{ .width = @intCast(width), .height = @intCast(height), .data = data, .allocator = allocator };
    }

    pub fn deinit(self: *Field) void {
        self.allocator.free(self.data);
    }

    pub fn contains(self: Field, point: Point) bool {
        return point.row >= 0 and point.row < self.height and point.col >= 0 and point.col < self.width;
    }

    pub fn at(self: Field, point: Point) !u8 {
        if (!self.contains(point)) {
            return error.OutOfFiledAccess;
        }
        const pos: usize = @intCast(point.row * self.width + point.col);
        return self.data[pos];
    }

    pub fn findPartNumbers(self: Field) std.ArrayList(PartNumber) {
        var numbers = std.ArrayList(PartNumber).init(self.allocator);

        var row: i32 = 0;
        while (row < self.height) : (row += 1) {
            var currentNumber: i32 = 0;
            var neighborParts = std.ArrayList(Point).init(self.allocator);

            var col: i32 = 0;
            while (col < self.width) : (col += 1) {
                const currentPoint = Point{ .row = row, .col = col };
                const currentChar = self.at(currentPoint) catch unreachable;

                switch (currentChar) {
                    '0'...'9' => {
                        currentNumber = currentNumber * 10 + @as(i32, std.fmt.charToDigit(currentChar, 10) catch unreachable);
                        loop: for (currentPoint.neighbors()) |neighborPoint| {
                            if (!self.contains(neighborPoint)) continue;
                            const neighborChar = self.at(neighborPoint) catch unreachable;
                            if (!std.ascii.isDigit(neighborChar) and neighborChar != '.') {
                                // check if we already have that point covered, since zig does not have sets
                                for (neighborParts.items) |part| {
                                    if (std.meta.eql(part, neighborPoint)) {
                                        continue :loop;
                                    }
                                }
                                neighborParts.append(neighborPoint) catch unreachable;
                            }
                        }
                    },
                    else => {
                        if (currentNumber != 0) {
                            if (neighborParts.items.len != 0) {
                                numbers.append(PartNumber{ .number = currentNumber, .neighborSymbols = neighborParts }) catch unreachable;
                            }
                            currentNumber = 0;
                            neighborParts = std.ArrayList(Point).init(self.allocator);
                        }
                    },
                }
            } else {
                if (currentNumber != 0) {
                    if (neighborParts.items.len != 0) {
                        numbers.append(PartNumber{ .number = currentNumber, .neighborSymbols = neighborParts }) catch unreachable;
                    } else {
                        neighborParts.deinit();
                    }
                    currentNumber = 0;
                }
            }
        }

        return numbers;
    }

    pub fn findGears(self: Field, partNumbers_: ?std.ArrayList(PartNumber)) i32 {
        var partNumbers = if (partNumbers_) |val| val else self.findPartNumbers();
        defer {
            if (partNumbers_ == null) {
                for (partNumbers.items) |n| n.deinit();
                partNumbers.deinit();
            }
        }

        var acc: i32 = 0;
        var row: i32 = 0;
        while (row < self.height) : (row += 1) {
            var col: i32 = 0;
            while (col < self.width) : (col += 1) {
                const p = Point{ .row = row, .col = col };
                const c = self.at(p) catch unreachable;

                if (c != '*') {
                    continue;
                }

                var neighborParts = std.ArrayList(*const PartNumber).init(self.allocator);
                defer neighborParts.deinit();

                loop: for (partNumbers.items) |*item| {
                    for (item.neighborSymbols.items) |n| {
                        if (std.meta.eql(n, p)) {
                            neighborParts.append(item) catch unreachable;
                            continue :loop;
                        }
                    }
                }

                if (neighborParts.items.len == 2) {
                    const a = neighborParts.items[0].number;
                    const b = neighborParts.items[1].number;
                    acc += a * b;
                }
            }
        }

        return acc;
    }

    pub fn print(self: Field) void {
        const w: usize = @intCast(self.width);
        const h: usize = @intCast(self.height);

        var buf = self.allocator.alloc(u8, h * (w + 1)) catch unreachable;
        defer self.allocator.free(buf);

        var row: usize = 0;
        while (row < h) : (row += 1) {
            std.mem.copy(u8, buf[row * (w + 1) ..], self.data[row * w .. (row + 1) * w]);
            buf[(row + 1) * (w + 1) - 1] = '\n';
        }

        util.print("{s}\n", .{buf});
    }
};

pub fn task_01_field(field: Field) i32 {
    var partNumbers = field.findPartNumbers();
    defer partNumbers.deinit();
    defer for (partNumbers.items) |n| n.deinit();

    return task_01(partNumbers);
}

pub fn task_01(partNumbers: std.ArrayList(PartNumber)) i32 {
    var acc: i32 = 0;
    for (partNumbers.items) |item| {
        acc += item.number;
    }
    return acc;
}

pub fn task_02_field(field: Field) i32 {
    return field.findGears(null);
}

pub fn task_02(field: Field, partNumbers: ?std.ArrayList(PartNumber)) i32 {
    return field.findGears(partNumbers);
}

test "sample results efficient" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_03.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var field = Field.initFromInput(input, allocator);
    defer field.deinit();

    var partNumbers = field.findPartNumbers();
    defer partNumbers.deinit();
    defer for (partNumbers.items) |n| n.deinit();

    try std.testing.expectEqual(@as(i32, 4361), task_01(partNumbers));
    try std.testing.expectEqual(@as(i32, 467835), task_02(field, partNumbers));
}

test "sample results individual" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_03.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var field = Field.initFromInput(input, allocator);
    defer field.deinit();

    try std.testing.expectEqual(@as(i32, 4361), task_01_field(field));
    try std.testing.expectEqual(@as(i32, 467835), task_02_field(field));
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

    var field = Field.initFromInput(input, allocator);
    defer field.deinit();

    var partNumbers = field.findPartNumbers();
    defer partNumbers.deinit();
    defer for (partNumbers.items) |n| n.deinit();

    std.debug.print("Day 03 Solution 1: {}\n", .{task_01(partNumbers)});
    std.debug.print("Day 03 Solution 2: {}\n", .{task_02(field, partNumbers)});
}
