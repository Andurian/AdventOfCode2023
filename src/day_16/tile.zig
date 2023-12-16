const std = @import("std");
const util = @import("util");

const Head = @import("Head.zig");

pub const Tile = struct {
    pub const VTable = struct {
        process: *const fn (head: Head) [2]?Head,
        toChar: *const fn () u8,
    };

    vtable: VTable,

    pub fn process(self: Tile, head: Head) [2]?Head {
        return self.vtable.process(head);
    }

    pub fn toChar(self: Tile) u8 {
        return self.vtable.toChar();
    }

    pub fn make(c: u8) Tile {
        return switch (c) {
            '/' => MirrorPositiveSlopeTile.make(),
            '\\' => MirrorNegativeSlopeTile.make(),
            '-' => HorizontalSplitterTile.make(),
            '|' => VerticalSplitterTile.make(),
            else => EmptyTile.make(),
        };
    }
};

const EmptyTile = struct {
    pub fn process(head: Head) [2]?Head {
        return [_]?Head{ .{ .pos = head.pos.neighbor(head.orientation), .orientation = head.orientation }, null };
    }

    pub fn toChar() u8 {
        return '.';
    }

    pub fn make() Tile {
        return .{ .vtable = .{ .process = process, .toChar = toChar } };
    }
};

const MirrorPositiveSlopeTile = struct {
    pub fn process(head: Head) [2]?Head {
        const newOrientation = switch (head.orientation) {
            util.Direction.North => util.Direction.East,
            util.Direction.East => util.Direction.North,
            util.Direction.South => util.Direction.West,
            util.Direction.West => util.Direction.South,
        };
        return [_]?Head{
            .{ .pos = head.pos.neighbor(newOrientation), .orientation = newOrientation }, //
            null,
        };
    }

    pub fn toChar() u8 {
        return '/';
    }

    pub fn make() Tile {
        return .{ .vtable = .{ .process = process, .toChar = toChar } };
    }
};

const MirrorNegativeSlopeTile = struct {
    pub fn process(head: Head) [2]?Head {
        const newOrientation = switch (head.orientation) {
            util.Direction.North => util.Direction.West,
            util.Direction.East => util.Direction.South,
            util.Direction.South => util.Direction.East,
            util.Direction.West => util.Direction.North,
        };
        return [_]?Head{
            .{ .pos = head.pos.neighbor(newOrientation), .orientation = newOrientation }, //
            null,
        };
    }

    pub fn toChar() u8 {
        return '\\';
    }

    pub fn make() Tile {
        return .{ .vtable = .{ .process = process, .toChar = toChar } };
    }
};

const HorizontalSplitterTile = struct {
    pub fn process(head: Head) [2]?Head {
        if (head.orientation == util.Direction.North or head.orientation == util.Direction.South) {
            return [_]?Head{
                .{ .pos = head.pos.neighbor(util.Direction.West), .orientation = util.Direction.West }, //
                .{ .pos = head.pos.neighbor(util.Direction.East), .orientation = util.Direction.East },
            };
        }

        return [_]?Head{ .{ .pos = head.pos.neighbor(head.orientation), .orientation = head.orientation }, null };
    }

    pub fn toChar() u8 {
        return '-';
    }

    pub fn make() Tile {
        return .{ .vtable = .{ .process = process, .toChar = toChar } };
    }
};

const VerticalSplitterTile = struct {
    pub fn process(head: Head) [2]?Head {
        if (head.orientation == util.Direction.East or head.orientation == util.Direction.West) {
            return [_]?Head{
                .{ .pos = head.pos.neighbor(util.Direction.North), .orientation = util.Direction.North }, //
                .{ .pos = head.pos.neighbor(util.Direction.South), .orientation = util.Direction.South },
            };
        }

        return [_]?Head{ .{ .pos = head.pos.neighbor(head.orientation), .orientation = head.orientation }, null };
    }

    pub fn toChar() u8 {
        return '|';
    }

    pub fn make() Tile {
        return .{ .vtable = .{ .process = process, .toChar = toChar } };
    }
};
