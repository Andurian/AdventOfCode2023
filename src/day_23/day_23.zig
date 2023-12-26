const std = @import("std");
const util = @import("util");

pub fn id(c: u8) u8 {
    return c;
}

pub fn lastDigit(x: usize) u8 {
    return @intCast((x % 10) + '0');
}

pub fn dirToSymbol(c: u8) util.Direction {
    return switch (c) {
        '^' => .North,
        '>' => .East,
        'v' => .South,
        '<' => .West,
        else => unreachable,
    };
}

pub fn orderedNeighbors(p: util.Point) [4]util.Point {
    var ret: [4]util.Point = undefined;

    ret[@intFromEnum(util.Direction.North)] = .{ .row = p.row - 1, .col = p.col };
    ret[@intFromEnum(util.Direction.East)] = .{ .row = p.row, .col = p.col + 1 };
    ret[@intFromEnum(util.Direction.South)] = .{ .row = p.row + 1, .col = p.col };
    ret[@intFromEnum(util.Direction.West)] = .{ .row = p.row, .col = p.col - 1 };

    return ret;
}

const SearchState = enum {
    Unvisited,
    Visited,
    VisitedNode,

    pub fn toChar(s: SearchState) u8 {
        return switch (s) {
            .Unvisited => '#',
            .Visited => '.',
            .VisitedNode => 'O',
        };
    }
};

pub fn findIntersections(field: util.Field(u8), start: util.Point, target: util.Point, allocator: std.mem.Allocator) std.ArrayList(util.Point) {
    var nodes = std.ArrayList(util.Point).init(allocator);

    nodes.append(start) catch unreachable;

    var nodeStack = std.ArrayList(util.Point).init(allocator);
    defer nodeStack.deinit();

    var directionStack = std.ArrayList(util.Direction).init(allocator);
    defer directionStack.deinit();

    var visited = util.Field(SearchState).initWithDefault(field.width, field.height, .Unvisited, allocator);
    defer visited.deinit();
    visited.set(start, .VisitedNode);

    var candidates = std.ArrayList(util.Direction).initCapacity(allocator, 4) catch unreachable;
    defer candidates.deinit();

    nodeStack.append(start) catch unreachable;
    directionStack.append(.South) catch unreachable;

    while (nodeStack.popOrNull()) |currentNode| {
        var direction = directionStack.pop();
        var current = currentNode.neighbor(direction);
        visited.set(current, .Visited);

        while (true) {
            const neighbors = orderedNeighbors(current);
            candidates.clearRetainingCapacity();
            for (neighbors, 0..) |neighbor, i| {
                if (field.contains(neighbor) and field.at(neighbor) catch unreachable != '#') {
                    const v = visited.at(neighbor) catch unreachable;
                    if (v == .Unvisited) {
                        candidates.append(@enumFromInt(i)) catch unreachable;
                    }
                }
            }
            if (candidates.items.len == 0) break;
            if (candidates.items.len == 1) {
                current = current.neighbor(candidates.items[0]);
                visited.set(current, .Visited);
            } else {
                nodes.append(current) catch unreachable;
                visited.set(current, .VisitedNode);

                for (candidates.items) |candidate| {
                    nodeStack.append(current) catch unreachable;
                    directionStack.append(candidate) catch unreachable;
                }
                break;
            }
        }
    }
    nodes.append(target) catch unreachable;

    return nodes;
}

pub fn findDistancesBetweenIntersections(field: util.Field(u8), nodes: []const util.Point, start: util.Point, target: util.Point, allocator: std.mem.Allocator) util.Field(i32) {
    var nodeToIdx = std.AutoHashMap(util.Point, i32).init(allocator);
    defer nodeToIdx.deinit();

    for (nodes, 0..) |n, i| nodeToIdx.put(n, @intCast(i)) catch unreachable;

    var distanceMatrix = util.Field(i32).initWithDefault(@intCast(nodes.len), @intCast(nodes.len), -1, allocator);

    var nodeStack = std.ArrayList(util.Point).init(allocator);
    defer nodeStack.deinit();

    var directionStack = std.ArrayList(util.Direction).init(allocator);
    defer directionStack.deinit();

    var visited = util.Field(SearchState).initWithDefault(field.width, field.height, .Unvisited, allocator);
    defer visited.deinit();
    visited.set(start, .VisitedNode);
    visited.set(target, .VisitedNode);

    var candidates = std.ArrayList(util.Direction).initCapacity(allocator, 4) catch unreachable;
    defer candidates.deinit();

    nodeStack.append(start) catch unreachable;
    directionStack.append(.South) catch unreachable;

    while (nodeStack.popOrNull()) |currentNode| {
        const startNodeIdx = nodeToIdx.get(currentNode).?;

        var direction = directionStack.pop();
        var current = currentNode.neighbor(direction);
        visited.set(current, .Visited);

        var len: usize = 1;

        while (true) {
            const neighbors = orderedNeighbors(current);
            candidates.clearRetainingCapacity();
            for (neighbors, 0..) |neighbor, i| {
                if (field.contains(neighbor) and field.at(neighbor) catch unreachable != '#') {
                    const v = visited.at(neighbor) catch unreachable;
                    if (v == .Unvisited) {
                        candidates.append(@enumFromInt(i)) catch unreachable;
                    } else if (v == .VisitedNode and !std.meta.eql(neighbor, currentNode)) {
                        const nodeIdx = nodeToIdx.get(neighbor).?;
                        distanceMatrix.set(.{ .row = startNodeIdx, .col = nodeIdx }, @intCast(len + 1));
                        distanceMatrix.set(.{ .row = nodeIdx, .col = startNodeIdx }, @intCast(len + 1));
                    }
                }
            }
            if (candidates.items.len == 0) break;
            if (candidates.items.len == 1) {
                current = current.neighbor(candidates.items[0]);
                visited.set(current, .Visited);
                len += 1;
            } else {
                visited.set(current, .VisitedNode);
                const nodeIdx = nodeToIdx.get(current).?;
                distanceMatrix.set(.{ .row = startNodeIdx, .col = nodeIdx }, @intCast(len));
                distanceMatrix.set(.{ .row = nodeIdx, .col = startNodeIdx }, @intCast(len));

                for (candidates.items) |candidate| {
                    nodeStack.append(current) catch unreachable;
                    directionStack.append(candidate) catch unreachable;
                }
                break;
            }
        }
    }

    return distanceMatrix;
}

const Graph = struct {
    nodes: std.ArrayList(util.Point),
    idxToNode: std.AutoHashMap(util.Point, i32),
    distanceMatrix: util.Field(i32),
    start: util.Point,
    target: util.Point,

    masks: [64]u64,
    allocator: std.mem.Allocator,

    pub fn init(field: util.Field(u8), start: util.Point, target: util.Point, allocator: std.mem.Allocator) Graph {
        var nodes = findIntersections(field, start, target, allocator);

        var distanceMatrix = findDistancesBetweenIntersections(field, nodes.items, start, target, allocator);
        var idxToNode = std.AutoHashMap(util.Point, i32).init(allocator);
        for (nodes.items, 0..) |n, i| idxToNode.put(n, @intCast(i)) catch unreachable;

        util.print("LEN: {}\n", .{nodes.items.len});
        distanceMatrix.debugPrint();

        var masks = [_]u64{1} ** 64;
        var i: usize = 1;
        var j: u64 = 1;
        while (i < 64) : (i += 1) {
            j *= 2;
            masks[i] = j;
        }

        return .{ .nodes = nodes, .masks = masks, .start = start, .target = target, .idxToNode = idxToNode, .distanceMatrix = distanceMatrix, .allocator = allocator };
    }

    pub fn deinit(self: *Graph) void {
        self.nodes.deinit();
        self.idxToNode.deinit();
        self.distanceMatrix.deinit();
    }

    pub fn dfs(self: Graph, visited_: u64, currentNodeIdx: i32, targetNodeIdx: i32) i32 {
        if (currentNodeIdx == targetNodeIdx) return 0;

        const visited = visited_ | self.masks[@intCast(currentNodeIdx)];
        var i: i32 = 0;
        var max: i32 = 0;
        while (i < self.nodes.items.len) : (i += 1) {
            if (visited & self.masks[@intCast(i)] != 0) continue;
            const d = self.distanceMatrix.at(.{ .row = currentNodeIdx, .col = i }) catch unreachable;
            if (d == -1) continue;
            max = @max(max, d + self.dfs(visited, i, targetNodeIdx));
        }
        return max;
    }

    pub fn longestPath(self: Graph) i32 {
        const startIdx = self.idxToNode.get(self.start).?;
        const targetIdx = self.idxToNode.get(self.target).?;

        return self.dfs(0, startIdx, targetIdx);
    }
};

const DfsContext = struct {
    path: std.ArrayList(util.Point),
    visited: util.Field(bool),
    ignoreSlopes: bool,
    allocator: std.mem.Allocator,

    pub fn init(ignoreSlopes: bool, field: util.Field(u8), allocator: std.mem.Allocator) DfsContext {
        return .{
            .path = std.ArrayList(util.Point).init(allocator),
            .visited = util.Field(bool).initWithDefault(field.width, field.height, false, allocator),
            .ignoreSlopes = ignoreSlopes,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DfsContext) void {
        self.path.deinit();
        self.visited.deinit();
    }

    pub fn clone(self: DfsContext) DfsContext {
        var path = std.ArrayList(util.Point).init(self.allocator);
        var visited = self.visited.clone();

        path.appendSlice(self.path.items) catch unreachable;

        return .{ .path = path, .visited = visited, .ignoreSlopes = self.ignoreSlopes, .allocator = self.allocator };
    }
};

pub fn dfsStart(ignoreSlopes: bool, field: util.Field(u8), allocator: std.mem.Allocator) ?usize {
    const start = util.Point{ .row = 0, .col = 1 };
    const target = util.Point{ .row = field.height - 1, .col = field.width - 2 };

    var ctx = DfsContext.init(ignoreSlopes, field, allocator);
    defer ctx.deinit();

    ctx.path.append(start) catch unreachable;
    ctx.visited.set(start, true);

    return dfsStep(.South, ctx, field, target);
}

pub fn dfsSingleStep(direction: util.Direction, ctx: *DfsContext, field: util.Field(u8)) ?util.Point {
    var current = ctx.path.items[ctx.path.items.len - 1];

    const nextPos = current.neighbor(direction);
    if (!field.contains(nextPos)) @panic("Falling off the edge");

    const c = field.at(nextPos) catch unreachable;

    if (c == '#') @panic("Banging my head against a wall!");

    if (c == '.' or ctx.ignoreSlopes) {
        ctx.path.append(nextPos) catch unreachable;
        ctx.visited.set(nextPos, true);
        return nextPos;
    }

    if (dirToSymbol(c) != direction) return null; // Walkin on a slope in the wrong direction

    // Now we are on a slope in the correct direction
    ctx.path.append(nextPos) catch unreachable;
    ctx.visited.set(nextPos, true);
    return dfsSingleStep(direction, ctx, field); // Step again off the slope
}

pub fn dfsStep(nextDirection: util.Direction, ctxOriginal: DfsContext, field: util.Field(u8), target: util.Point) ?usize {
    var ctx = ctxOriginal.clone();
    defer ctx.deinit();

    var current = dfsSingleStep(nextDirection, &ctx, field);
    if (current == null) return null;
    if (std.meta.eql(current.?, target)) {
        util.print("Preliminary: {}\n", .{ctx.path.items.len - 1});
        return ctx.path.items.len - 1;
    }

    var candidates = std.ArrayList(util.Direction).initCapacity(ctx.allocator, 4) catch unreachable;
    defer candidates.deinit();

    while (true) {
        const neighbors = orderedNeighbors(current.?);
        candidates.clearRetainingCapacity();
        for (neighbors, 0..) |neighbor, i| {
            if (field.contains(neighbor) //
            and field.at(neighbor) catch unreachable != '#' //
            and ctx.visited.at(neighbor) catch unreachable == false) {
                candidates.append(@enumFromInt(i)) catch unreachable;
            }
        }
        if (candidates.items.len == 0) return null;
        if (candidates.items.len == 1) {
            current = dfsSingleStep(candidates.items[0], &ctx, field);
            if (current == null) return null;
            if (std.meta.eql(current.?, target)) {
                util.print("Preliminary: {}\n", .{ctx.path.items.len - 1});
                return ctx.path.items.len - 1;
            }
        } else {
            var max: usize = 0;
            //util.print("Branch {} at {any}\n", .{ candidates.items.len, current });
            for (candidates.items) |candidate| {
                if (dfsStep(candidate, ctx, field, target)) |steps| {
                    max = @max(max, steps);
                }
            }
            return max;
        }
    }
    unreachable;
}

pub fn task_01(field: util.Field(u8), allocator: std.mem.Allocator) usize {
    if (dfsStart(false, field, allocator)) |steps| {
        return steps;
    }
    @panic("No path found");
}

pub fn task_02(field: util.Field(u8), allocator: std.mem.Allocator) usize {
    if (dfsStart(true, field, allocator)) |steps| {
        return steps;
    }
    @panic("No path found");
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

    var field = util.Field(u8).initFromInput(input, id, allocator);
    defer field.deinit();

    const start = util.Point{ .row = 0, .col = 1 };
    const target = util.Point{ .row = field.height - 1, .col = field.width - 2 };

    var g = Graph.init(field, start, target, allocator);
    defer g.deinit();

    util.print("PPP: {}\n", .{g.longestPath()});
    // util.print("Day 23 Solution 1: {}\n", .{task_01(field, allocator)});
    // util.print("Day 23 Solution 2: {}\n", .{task_02(field, allocator)});

}
