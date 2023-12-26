const std = @import("std");
const util = @import("util");

const Graph = struct {
    nodes: std.StringHashMap(i32),
    nodesByIdx: std.ArrayList([]const u8),
    adjacencyMatrix: util.Field(bool),
    allocator: std.mem.Allocator,

    pub fn fromInput(input: [][]const u8, allocator: std.mem.Allocator) Graph {
        var idx: i32 = 0;
        var nodes = std.StringHashMap(i32).init(allocator);
        var nodesByIdx = std.ArrayList([]const u8).init(allocator);

        for (input) |line| {
            var it = std.mem.tokenize(u8, line, ": ");
            const currentNode = it.next().?;
            if (!nodes.contains(currentNode)) {
                nodes.put(currentNode, idx) catch unreachable;
                nodesByIdx.append(currentNode) catch unreachable;
                idx += 1;
            }
            while (it.next()) |connectedNode| {
                if (!nodes.contains(connectedNode)) {
                    nodes.put(connectedNode, idx) catch unreachable;
                    nodesByIdx.append(connectedNode) catch unreachable;
                    idx += 1;
                }
            }
        }

        const numNodes: i32 = @intCast(nodes.count());

        var adjacencyMatrix = util.Field(bool).initWithDefault(numNodes, numNodes, false, allocator);
        for (input) |line| {
            var it = std.mem.tokenize(u8, line, ": ");
            const currentNode = it.next().?;
            const currentNodeIdx = nodes.get(currentNode).?;
            while (it.next()) |connectedNode| {
                const connectedNodeIdx = nodes.get(connectedNode).?;
                adjacencyMatrix.set(.{ .row = currentNodeIdx, .col = connectedNodeIdx }, true);
                adjacencyMatrix.set(.{ .row = connectedNodeIdx, .col = currentNodeIdx }, true);
            }
        }

        return .{ .nodes = nodes, .nodesByIdx = nodesByIdx, .adjacencyMatrix = adjacencyMatrix, .allocator = allocator };
    }

    pub fn deinit(self: *Graph) void {
        self.nodes.deinit();
        self.nodesByIdx.deinit();
        self.adjacencyMatrix.deinit();
    }

    pub fn printGraphviz(self: Graph) void {
        var i: i32 = 0;
        while (i < self.nodes.count()) : (i += 1) {
            const currentNode = self.nodesByIdx.items[@intCast(i)];
            var j = i + 1;
            while (j < self.nodes.count()) : (j += 1) {
                const connectedNode = self.nodesByIdx.items[@intCast(j)];
                if (self.adjacencyMatrix.at(.{ .row = i, .col = j }) catch unreachable) {
                    util.print("{s} -- {s}\n", .{ currentNode, connectedNode });
                }
            }
        }
    }

    fn dfs(self: Graph, visited: []bool, currentNodeIdx: i32) usize {
        visited[@intCast(currentNodeIdx)] = true;
        var size: usize = 1;

        var connectedNodeIdx: i32 = 0;
        while (connectedNodeIdx < self.nodes.count()) : (connectedNodeIdx += 1) {
            if (self.adjacencyMatrix.at(.{ .row = currentNodeIdx, .col = connectedNodeIdx }) catch unreachable and !visited[@intCast(connectedNodeIdx)]) {
                size += self.dfs(visited, connectedNodeIdx);
            }
        }

        return size;
    }

    pub fn componentSize(self: Graph) []usize {
        var sizes = std.ArrayList(usize).init(self.allocator);
        defer sizes.deinit();

        var visited = self.allocator.alloc(bool, self.nodes.count()) catch unreachable;
        defer self.allocator.free(visited);

        @memset(visited, false);

        while (util.firstOf(bool, visited, false)) |unvisitedNodeIdx| {
            sizes.append(self.dfs(visited, @intCast(unvisitedNodeIdx))) catch unreachable;
        }

        return sizes.toOwnedSlice() catch unreachable;
    }

    pub fn removeEdge(self: *Graph, node1: []const u8, node2: []const u8) void {
        const node1Idx = self.nodes.get(node1).?;
        const node2Idx = self.nodes.get(node2).?;

        self.adjacencyMatrix.set(.{ .row = node1Idx, .col = node2Idx }, false);
        self.adjacencyMatrix.set(.{ .row = node2Idx, .col = node1Idx }, false);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile(args[1], allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var g = Graph.fromInput(input, allocator);
    defer g.deinit();

    //g.printGraphviz();
    {
        var s = g.componentSize();
        defer allocator.free(s);
        util.print("{any}\n", .{s});
    }

    // For now... look at graphviz and mark the edges...

    // g.removeEdge("gpz", "prk");
    // g.removeEdge("qdv", "zhg");
    // g.removeEdge("lsk", "rfq");

    g.removeEdge("zlv", "bmx");
    g.removeEdge("tpb", "xsl");
    g.removeEdge("qpg", "lrd");

    {
        var s = g.componentSize();
        defer allocator.free(s);
        util.print("{any}\n", .{s});
    }
}
