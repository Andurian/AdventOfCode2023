const std = @import("std");
const util = @import("util");

// Improvements still to do:
// Handle start and target nodes differently to reduce total node size (don't have a node with 0 directional steps for each grid position)
// Add an Iterator to go over all possible nodes and directions to avoid writing the same loop every time
// Run the algo only once for task 2
// Replace Hash Map by linear array for better performance?

const Position = struct {
    row: i32,
    col: i32,
    entryDirection: util.Direction,
    directionalSteps: usize,

    pub fn pos(self: Position) util.Point {
        return .{ .row = self.row, .col = self.col };
    }
};

const Vertex = struct {
    source: Position,
    target: Position,
    direction: util.Direction,
    cost: i32,
};

const Node = struct {
    pos: Position,
    neighbors: [4]?Vertex,
};

pub fn costFromChar(c: u8) i32 {
    return @intCast(c - '0');
}

const Graph = struct {
    nodes: std.AutoHashMap(Position, Node),
    field: util.Field(i32),
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) Graph {
        var field = util.Field(i32).initFromInput(input, costFromChar, allocator);
        var nodes = std.AutoHashMap(Position, Node).init(allocator);

        // generate nodes
        var it = field.positionIterator();
        while (it.next()) |pos| {
            inline for (@typeInfo(util.Direction).Enum.fields) |direction| {
                var numSteps: usize = 0;
                while (numSteps <= 3) : (numSteps += 1) {
                    const nodePos = Position{ //
                        .row = pos.row,
                        .col = pos.col,
                        .entryDirection = @enumFromInt(direction.value),
                        .directionalSteps = numSteps,
                    };
                    const node = Node{ .pos = nodePos, .neighbors = undefined };
                    nodes.put(nodePos, node) catch unreachable;
                }
            }
        }

        // generate vertices
        it = field.positionIterator();
        while (it.next()) |pos| {
            inline for (@typeInfo(util.Direction).Enum.fields) |direction| {
                var numSteps: usize = 0;
                while (numSteps <= 3) : (numSteps += 1) {
                    const nodePos = Position{ //
                        .row = pos.row,
                        .col = pos.col,
                        .entryDirection = @enumFromInt(direction.value),
                        .directionalSteps = numSteps,
                    };
                    var node = nodes.getPtr(nodePos).?;

                    inline for (@typeInfo(util.Direction).Enum.fields) |stepDirectionV| {
                        const stepDirection: util.Direction = @enumFromInt(stepDirectionV.value);
                        const neighborPos = nodePos.pos().neighbor(stepDirection);
                        if (!field.contains(neighborPos) or (stepDirection == nodePos.entryDirection and nodePos.directionalSteps == 3) or stepDirection == nodePos.entryDirection.opposite()) {
                            node.neighbors[@intFromEnum(stepDirection)] = null;
                        } else {
                            const neighborNodePos = Position{ //
                                .row = neighborPos.row,
                                .col = neighborPos.col,
                                .entryDirection = stepDirection,
                                .directionalSteps = if (stepDirection == nodePos.entryDirection) nodePos.directionalSteps + 1 else 1,
                            };
                            const vertex = Vertex{ .source = nodePos, .target = neighborNodePos, .direction = stepDirection, .cost = field.at(neighborPos) catch unreachable };
                            node.neighbors[@intFromEnum(stepDirection)] = vertex;
                        }
                    }
                }
            }
        }
        return .{ .nodes = nodes, .field = field, .allocator = allocator };
    }

    pub fn initFromInputTask2(input: [][]const u8, allocator: std.mem.Allocator) Graph {
        var field = util.Field(i32).initFromInput(input, costFromChar, allocator);
        var nodes = std.AutoHashMap(Position, Node).init(allocator);

        // generate nodes
        var it = field.positionIterator();
        while (it.next()) |pos| {
            inline for (@typeInfo(util.Direction).Enum.fields) |direction| {
                var numSteps: usize = 0;
                while (numSteps <= 10) : (numSteps += 1) {
                    const nodePos = Position{ //
                        .row = pos.row,
                        .col = pos.col,
                        .entryDirection = @enumFromInt(direction.value),
                        .directionalSteps = numSteps,
                    };
                    const node = Node{ .pos = nodePos, .neighbors = undefined };
                    nodes.put(nodePos, node) catch unreachable;
                }
            }
        }

        // generate vertices
        it = field.positionIterator();
        while (it.next()) |pos| {
            inline for (@typeInfo(util.Direction).Enum.fields) |direction| {
                var numSteps: usize = 0;
                while (numSteps <= 10) : (numSteps += 1) {
                    const nodePos = Position{ //
                        .row = pos.row,
                        .col = pos.col,
                        .entryDirection = @enumFromInt(direction.value),
                        .directionalSteps = numSteps,
                    };
                    var node = nodes.getPtr(nodePos).?;

                    inline for (@typeInfo(util.Direction).Enum.fields) |stepDirectionV| {
                        const stepDirection: util.Direction = @enumFromInt(stepDirectionV.value);
                        const neighborPos = nodePos.pos().neighbor(stepDirection);
                        if (!field.contains(neighborPos) //
                        or (stepDirection == nodePos.entryDirection and nodePos.directionalSteps >= 10) //
                        or (stepDirection != nodePos.entryDirection and nodePos.directionalSteps < 4) //
                        or stepDirection == nodePos.entryDirection.opposite()) {
                            node.neighbors[@intFromEnum(stepDirection)] = null;
                        } else {
                            const neighborNodePos = Position{ //
                                .row = neighborPos.row,
                                .col = neighborPos.col,
                                .entryDirection = stepDirection,
                                .directionalSteps = if (stepDirection == nodePos.entryDirection) nodePos.directionalSteps + 1 else 1,
                            };
                            const vertex = Vertex{ .source = nodePos, .target = neighborNodePos, .direction = stepDirection, .cost = field.at(neighborPos) catch unreachable };
                            node.neighbors[@intFromEnum(stepDirection)] = vertex;
                        }
                    }
                }
            }
        }
        return .{ .nodes = nodes, .field = field, .allocator = allocator };
    }

    pub fn deinit(self: *Graph) void {
        self.nodes.deinit();
        self.field.deinit();
    }
};

pub fn compare(dist: *std.AutoHashMap(Position, i32), a: Position, b: Position) std.math.Order {
    const dA = dist.get(a);
    const dB = dist.get(b);

    if (dA == null) {
        if (dB == null) {
            return std.math.Order.eq;
        } else {
            return std.math.Order.gt;
        }
    } else {
        if (dB == null) {
            return std.math.Order.lt;
        } else {
            return std.math.order(dA.?, dB.?);
        }
    }
}

pub fn dijkstra(g: Graph, source: Position, target: util.Point, minTargetSteps: ?i32, allocator: std.mem.Allocator) i32 {
    var dist = std.AutoHashMap(Position, i32).init(allocator);
    defer dist.deinit();

    var prev = std.AutoHashMap(Position, Position).init(allocator);
    defer prev.deinit();

    var queue = std.PriorityQueue(Position, *std.AutoHashMap(Position, i32), compare).init(allocator, &dist);
    defer queue.deinit();

    dist.put(source, 0) catch unreachable;
    queue.add(source) catch unreachable;

    while (queue.removeOrNull()) |pos| {
        //util.print("Process: {any} \t Remaining: {}\n", .{ pos, queue.len });

        var node = g.nodes.getPtr(pos).?;
        var nodeDist = dist.get(pos).?;

        if (pos.row == target.row and pos.col == target.col and (minTargetSteps == null or pos.directionalSteps > minTargetSteps.?)) {
            //util.print("Done: {} ({})\n", .{ nodeDist, pos.directionalSteps });
            return nodeDist;
        }

        inline for (@typeInfo(util.Direction).Enum.fields) |stepDirection| {
            // const stepDirection: util.Direction = @enumFromInt(stepDirectionV.value);
            const vertexOpt = node.neighbors[stepDirection.value];
            if (vertexOpt != null) {
                var neighborNodePos = vertexOpt.?.target;
                //if (util.contains_(Position, queue.items, neighborNodePos)) {
                const distToNode = nodeDist + vertexOpt.?.cost;
                const calculatedDist = dist.get(neighborNodePos);
                if (calculatedDist == null or distToNode < calculatedDist.?) {
                    //util.print("\tAdd: {any}\n", .{neighborNodePos});
                    dist.put(neighborNodePos, distToNode) catch unreachable;
                    prev.put(neighborNodePos, pos) catch unreachable;
                    queue.add(neighborNodePos) catch unreachable;
                }
                //}
            }
        }
    }
    unreachable;
}

pub fn task_01(input: [][]const u8, allocator: std.mem.Allocator) i32 {
    var graph = Graph.initFromInput(input, allocator);
    defer graph.deinit();

    const start = Position{ .row = 0, .col = 0, .entryDirection = util.Direction.East, .directionalSteps = 0 };
    const target = util.Point{ .row = graph.field.height - 1, .col = graph.field.width - 1 };

    return dijkstra(graph, start, target, null, allocator);
}

pub fn task_02(input: [][]const u8, allocator: std.mem.Allocator) i32 {
    var graph = Graph.initFromInputTask2(input, allocator);
    defer graph.deinit();

    // Kind of a dirty hack. The current implementation requires us to choose a direction for the starting node.
    // Thats not a problem for Task 1 but for Task 2 it means starting in the east directon does not allow us to explore
    // moving south. Therefore we run dijkstra twice and check which starting direction is better.
    // Although it is really slow
    const start1 = Position{ .row = 0, .col = 0, .entryDirection = util.Direction.East, .directionalSteps = 0 };
    const start2 = Position{ .row = 0, .col = 0, .entryDirection = util.Direction.South, .directionalSteps = 0 };

    const target = util.Point{ .row = graph.field.height - 1, .col = graph.field.width - 1 };

    return @min( //
        dijkstra(graph, start1, target, 3, allocator), //
        dijkstra(graph, start2, target, 3, allocator));
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

    std.debug.print("Day 17 Solution 1: {}\n", .{task_01(input, allocator)});
    std.debug.print("Day 17 Solution 2: {}\n", .{task_02(input, allocator)});
}
