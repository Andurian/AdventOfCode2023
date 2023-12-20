const std = @import("std");
const util = @import("util");

pub const Pulse = enum { High, Low };

pub const Node = struct {
    pub const Type = enum { Button, Broadcast, FlipFlop, Conjunction, Output };
    const State = enum { On, Off };

    label: []const u8,
    nodeType: Type,
    inputSignals: std.StringArrayHashMap(Pulse),
    outgoingConnections: std.ArrayList([]const u8),

    state: State = .Off,

    hasReceivedLowPulse: bool = false,

    pub fn init(label: []const u8, nodeType: Type, allocator: std.mem.Allocator) Node {
        return .{
            .label = label,
            .nodeType = nodeType,
            .inputSignals = std.StringArrayHashMap(Pulse).init(allocator),
            .outgoingConnections = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Node) void {
        self.inputSignals.deinit();
        self.outgoingConnections.deinit();
    }

    pub fn addInput(self: *Node, label: []const u8) void {
        self.inputSignals.put(label, .Low) catch unreachable;
    }

    pub fn addOutput(self: *Node, label: []const u8) void {
        self.outgoingConnections.append(label) catch unreachable;
    }

    pub fn process(self: *Node, source: []const u8) ?Pulse {
        switch (self.nodeType) {
            .Button => {
                return .Low;
            },
            .Broadcast => {
                const pulse = self.inputSignals.get(source).?;
                return pulse;
            },
            .FlipFlop => {
                const pulse = self.inputSignals.get(source).?;
                switch (pulse) {
                    .High => return null,
                    .Low => {
                        switch (self.state) {
                            .Off => {
                                self.state = .On;
                                return .High;
                            },
                            .On => {
                                self.state = .Off;
                                return .Low;
                            },
                        }
                    },
                }
            },
            .Conjunction => {
                var it = self.inputSignals.iterator();
                while (it.next()) |entry| {
                    if (entry.value_ptr.* == .Low) {
                        self.hasReceivedLowPulse = true;
                        return .High;
                    }
                }
                return .Low;
            },
            .Output => {
                const pulse = self.inputSignals.get(source).?;
                if (pulse == .Low) {
                    self.hasReceivedLowPulse = true;
                }
                return null;
            },
        }
    }
};

pub const Network = struct {
    nodes: std.StringHashMap(Node),
    allocator: std.mem.Allocator,

    pub fn initFromInput(input: [][]const u8, allocator: std.mem.Allocator) Network {
        var nodes = std.StringHashMap(Node).init(allocator);

        for (input) |line| {
            var it = std.mem.tokenize(u8, line, "-> ,");
            const nodeStr = it.next().?;
            var node = switch (nodeStr[0]) {
                '%' => Node.init(nodeStr[1..], .FlipFlop, allocator),
                '&' => Node.init(nodeStr[1..], .Conjunction, allocator),
                else => Node.init(nodeStr, .Broadcast, allocator),
            };
            nodes.put(node.label, node) catch unreachable;
        }

        {
            var button = Node.init("button", .Button, allocator);
            nodes.put(button.label, button) catch unreachable;
        }

        for (input) |line| {
            var it = std.mem.tokenize(u8, line, "-> ,");
            var nodeStr = it.next().?;
            switch (nodeStr[0]) {
                '%' => nodeStr = nodeStr[1..],
                '&' => nodeStr = nodeStr[1..],
                else => {},
            }
            var node = nodes.getPtr(nodeStr).?;
            while (it.next()) |outputStr| {
                if (!nodes.contains(outputStr)) {
                    var outNode = Node.init(outputStr, .Output, allocator);
                    nodes.put(outputStr, outNode) catch unreachable;
                    node = nodes.getPtr(nodeStr).?; // reget due to map movement
                }
                var connected = nodes.getPtr(outputStr).?;
                node.addOutput(outputStr);
                connected.addInput(nodeStr);
            }
        }

        var broadcast = nodes.getPtr("broadcaster").?;
        var button = nodes.getPtr("button").?;

        button.addOutput("broadcaster");
        broadcast.addInput("button");

        return .{ .nodes = nodes, .allocator = allocator };
    }

    pub fn deinit(self: *Network) void {
        var it = self.nodes.valueIterator();
        while (it.next()) |node| {
            node.deinit();
        }
        self.nodes.deinit();
    }

    pub fn pressButton(self: *Network) [2]u64 {
        const Queue = std.TailQueue([]const u8);

        var processQueue = Queue{};
        var inputQueue = Queue{};

        {
            var node = self.allocator.create(Queue.Node) catch unreachable;
            node.* = .{ .data = "button" };
            processQueue.append(node);
        }

        {
            var node = self.allocator.create(Queue.Node) catch unreachable;
            node.* = .{ .data = "elf" };
            inputQueue.append(node);
        }

        var ret = [2]u64{ 0, 0 };

        while (processQueue.popFirst()) |currentNodeLabel| {
            defer self.allocator.destroy(currentNodeLabel);

            var inputNodeLabel = inputQueue.popFirst().?;
            defer self.allocator.destroy(inputNodeLabel);

            var currentNode = self.nodes.getPtr(currentNodeLabel.data).?;
            if (currentNode.process(inputNodeLabel.data)) |pulse| {
                const idx: usize = switch (pulse) {
                    .Low => 0,
                    .High => 1,
                };

                for (currentNode.outgoingConnections.items) |connection| {
                    ret[idx] += 1;

                    if (self.nodes.getPtr(connection)) |connectedNode| {
                        connectedNode.inputSignals.put(currentNode.label, pulse) catch unreachable;

                        {
                            var node = self.allocator.create(Queue.Node) catch unreachable;
                            node.* = .{ .data = connection };
                            processQueue.append(node);
                        }

                        {
                            var node = self.allocator.create(Queue.Node) catch unreachable;
                            node.* = .{ .data = currentNodeLabel.data };
                            inputQueue.append(node);
                        }
                    }

                    //util.print("{s} -{s}-> {s}\n", .{ currentNodeLabel.data, @tagName(pulse), connection });
                }
            }
        }

        return ret;
    }

    pub fn specialNodes(self: Network) std.ArrayList([]const u8) {
        var ret = std.ArrayList([]const u8).init(self.allocator);

        var outputNode = self.nodes.getPtr("rx").?;

        var bridgeNode: ?*Node = null;

        {
            var it = outputNode.inputSignals.iterator();
            while (it.next()) |entry| {
                if (bridgeNode != null) @panic("Hand crafted to input...");
                bridgeNode = self.nodes.getPtr(entry.key_ptr.*).?;
            }
        }

        var it = bridgeNode.?.inputSignals.iterator();
        while (it.next()) |entry| {
            ret.append(entry.key_ptr.*) catch unreachable;
        }

        return ret;
    }
};

pub fn task_01(input: [][]const u8, allocator: std.mem.Allocator) u64 {
    var network = Network.initFromInput(input, allocator);
    defer network.deinit();

    var lows: u64 = 0;
    var highs: u64 = 0;

    var i: i32 = 0;
    while (i < 1000) : (i += 1) {
        const r = network.pressButton();
        lows += r[0];
        highs += r[1];
    }

    return lows * highs;
}

pub fn task_02(input: [][]const u8, allocator: std.mem.Allocator) u64 {
    var network = Network.initFromInput(input, allocator);
    defer network.deinit();

    var specialNodes = network.specialNodes();
    defer specialNodes.deinit();

    var cycleLenghts = allocator.alloc(u64, specialNodes.items.len) catch unreachable;
    defer allocator.free(cycleLenghts);

    var cyclesFound = allocator.alloc(bool, specialNodes.items.len) catch unreachable;
    defer allocator.free(cyclesFound);

    @memset(cycleLenghts, 0);
    @memset(cyclesFound, false);

    var acc: u64 = 0;
    loop: while (true) {
        _ = network.pressButton();
        acc += 1;

        for (specialNodes.items, 0..) |item, i| {
            if (!cyclesFound[i]) {
                var node = network.nodes.getPtr(item).?;
                if (node.hasReceivedLowPulse) {
                    cyclesFound[i] = true;
                    cycleLenghts[i] = acc;

                    if (util.allEqual(bool, true, cyclesFound)) break :loop;
                }
            }
        }
    }

    var res = util.lcm(cycleLenghts[0], cycleLenghts[1]);
    for (cycleLenghts[2..]) |length| {
        res = util.lcm(res, length);
    }

    return res;
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

    util.print("Day 20 Solution 1: {}\n", .{task_01(input, allocator)});
    util.print("Day 20 Solution 2: {}\n", .{task_02(input, allocator)});
}
