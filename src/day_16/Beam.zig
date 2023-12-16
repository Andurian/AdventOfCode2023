const std = @import("std");
const util = @import("util");

const Head = @import("Head.zig");
const Tile = @import("tile.zig").Tile;

const Self = @This();

heads: std.ArrayList(Head),
occupancy: util.Field([4]bool),
allocator: std.mem.Allocator,

pub fn init(start: Head, field: util.Field(Tile), allocator: std.mem.Allocator) Self {
    var heads = std.ArrayList(Head).init(allocator);
    heads.append(start) catch unreachable;
    var occupancy = util.Field([4]bool).initWithDefault(field.width, field.height, [_]bool{false} ** 4, allocator);
    var occ = [_]bool{false} ** 4;
    occ[@intFromEnum(start.orientation)] = true;
    occupancy.set(start.pos, occ);

    return .{
        .heads = heads, //
        .occupancy = occupancy,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.heads.deinit();
    self.occupancy.deinit();
}

pub fn canAdvance(self: Self) bool {
    return self.heads.items.len > 0;
}

pub fn advance(self: *Self, field: util.Field(Tile)) void {
    var newHeads = std.ArrayList(Head).init(self.allocator);

    for (self.heads.items) |currentHead| {
        const currentTile = field.at(currentHead.pos) catch unreachable;
        const nextPositions = currentTile.process(currentHead);
        for (nextPositions) |p| {
            if (p == null) continue;

            const pos = p.?.pos;
            const orientation = p.?.orientation;

            if (!field.contains(pos)) continue;
            var occ = self.occupancy.at(pos) catch unreachable;

            if (occ[@intFromEnum(orientation)]) continue;
            occ[@intFromEnum(orientation)] = true;

            self.occupancy.set(pos, occ);
            newHeads.append(p.?) catch unreachable;
        }
    }

    self.heads.deinit();
    self.heads = newHeads;
}

pub fn advanceAll(self: *Self, field: util.Field(Tile)) void {
    while (self.canAdvance()) self.advance(field);
}

pub fn energizedFields(self: Self) i32 {
    var acc: i32 = 0;
    var it = self.occupancy.iterator();
    while (it.next()) |occ| {
        var hasBeam = false;
        for (occ) |b| hasBeam = if (b) true else hasBeam;
        if (hasBeam) acc += 1;
    }
    return acc;
}
