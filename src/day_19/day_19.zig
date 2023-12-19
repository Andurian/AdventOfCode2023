const std = @import("std");
const util = @import("util");

const Part = struct {
    x: u32,
    m: u32,
    a: u32,
    s: u32,

    pub const GetFn = *const fn (part: Part) u32;

    pub fn fromString(str: []const u8) Part {
        var it = std.mem.tokenize(u8, str, "{xmas}=,");

        const x = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable;
        const m = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable;
        const a = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable;
        const s = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable;

        return .{ .x = x, .m = m, .a = a, .s = s };
    }

    pub fn getX(self: Part) u32 {
        return self.x;
    }

    pub fn getM(self: Part) u32 {
        return self.m;
    }

    pub fn getA(self: Part) u32 {
        return self.a;
    }

    pub fn getS(self: Part) u32 {
        return self.s;
    }

    pub fn sum(self: Part) u32 {
        return self.x + self.m + self.a + self.s;
    }
};

// Probably simpler to represent by actual ranges but hey...
const PartRange = struct {
    x: [4000]bool = [_]bool{true} ** 4000,
    m: [4000]bool = [_]bool{true} ** 4000,
    a: [4000]bool = [_]bool{true} ** 4000,
    s: [4000]bool = [_]bool{true} ** 4000,

    const GetFn = *const fn (partRange: *PartRange) *[4000]bool;

    pub fn getX(self: *PartRange) *[4000]bool {
        return &self.x;
    }

    pub fn getM(self: *PartRange) *[4000]bool {
        return &self.m;
    }

    pub fn getA(self: *PartRange) *[4000]bool {
        return &self.a;
    }

    pub fn getS(self: *PartRange) *[4000]bool {
        return &self.s;
    }

    pub fn sum(self: PartRange) u64 {
        const cX = util.count(bool, &self.x, true);
        const cM = util.count(bool, &self.m, true);
        const cA = util.count(bool, &self.a, true);
        const cS = util.count(bool, &self.s, true);

        return cX * cM * cA * cS;
    }
};

const AnalysisSet = struct {
    splitRanges: std.StringHashMap(PartRange),
    acceptedRanges: std.ArrayList(PartRange),
    rulesToProcess: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) AnalysisSet {
        return .{ //
            .splitRanges = std.StringHashMap(PartRange).init(allocator),
            .acceptedRanges = std.ArrayList(PartRange).init(allocator),
            .rulesToProcess = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *AnalysisSet) void {
        self.splitRanges.deinit();
        self.acceptedRanges.deinit();
        self.rulesToProcess.deinit();
    }
};

const Compare = struct {
    pub const Fn = *const fn (input: u32, threshold: u32) bool;

    pub fn lt(input: u32, threshold: u32) bool {
        return input < threshold;
    }

    pub fn gt(input: u32, threshold: u32) bool {
        return input > threshold;
    }

    pub fn accept(_: u32, _: u32) bool {
        return true;
    }
};

const ModifyRange = struct {
    pub const Fn = *const fn (range: *[4000]bool, threshold: u32, bool) void;

    pub fn lt(range: *[4000]bool, threshold: u32, inverse: bool) void {
        const t = threshold - 1;
        if (!inverse) {
            @memset(range[t..], false);
        } else {
            @memset(range[0..t], false);
        }
    }

    pub fn gt(range: *[4000]bool, threshold: u32, inverse: bool) void {
        const t = threshold;
        if (!inverse) {
            @memset(range[0..t], false);
        } else {
            @memset(range[t..], false);
        }
    }

    pub fn nop(range: *[4000]bool, threshold: u32, inverse: bool) void {
        _ = inverse;
        _ = threshold;
        _ = range;
    }
};

const Decision = enum { Accept, Reject };
const Tag = enum { RuleDispatch, Decision };

const Rule = struct {
    const Outcome = union(Tag) {
        RuleDispatch: []const u8,
        Decision: Decision,
    };

    threshold: u32 = 0,

    getFromPart: Part.GetFn = Part.getX,
    getFromRange: PartRange.GetFn = PartRange.getX,

    cmp: Compare.Fn,
    modify: ModifyRange.Fn,

    outcome: Outcome,

    fn makeOutcome(str: []const u8) Outcome {
        if (std.mem.eql(u8, str, "A")) {
            return .{ .Decision = Decision.Accept };
        } else if (std.mem.eql(u8, str, "R")) {
            return .{ .Decision = Decision.Reject };
        } else {
            return .{ .RuleDispatch = str };
        }
    }

    pub fn fromString(str: []const u8) Rule {
        var it = std.mem.tokenize(u8, str, ":");
        const token1 = it.next().?;
        const token2 = it.next();

        if (token2 == null) {
            return .{ .cmp = Compare.accept, .modify = ModifyRange.nop, .outcome = makeOutcome(token1) };
        }

        const getFromPart: Part.GetFn = switch (token1[0]) {
            'x' => Part.getX,
            'm' => Part.getM,
            'a' => Part.getA,
            's' => Part.getS,
            else => unreachable,
        };

        const getFromRange: PartRange.GetFn = switch (token1[0]) {
            'x' => PartRange.getX,
            'm' => PartRange.getM,
            'a' => PartRange.getA,
            's' => PartRange.getS,
            else => unreachable,
        };

        const cmp: Compare.Fn = switch (token1[1]) {
            '>' => Compare.gt,
            '<' => Compare.lt,
            else => unreachable,
        };

        const modify: ModifyRange.Fn = switch (token1[1]) {
            '>' => ModifyRange.gt,
            '<' => ModifyRange.lt,
            else => unreachable,
        };

        const threshold = std.fmt.parseInt(u32, token1[2..], 10) catch unreachable;

        return .{ //
            .threshold = threshold,
            .getFromPart = getFromPart,
            .getFromRange = getFromRange,
            .cmp = cmp,
            .modify = modify,
            .outcome = makeOutcome(token2.?),
        };
    }

    pub fn process(self: Rule, part: Part) ?Outcome {
        if (self.cmp(self.getFromPart(part), self.threshold)) {
            return self.outcome;
        }
        return null;
    }

    pub fn splitPartRange(self: Rule, partRange: PartRange) [2]PartRange {
        var copy1 = partRange;
        var copy2 = partRange;

        self.modify(self.getFromRange(&copy1), self.threshold, false);
        self.modify(self.getFromRange(&copy2), self.threshold, true);

        return .{ copy1, copy2 };
    }
};

const MultiRule = struct {
    rules: []Rule,
    label: []const u8,
    allocator: std.mem.Allocator,

    pub fn fromString(str: []const u8, label: []const u8, allocator: std.mem.Allocator) MultiRule {
        var rules = std.ArrayList(Rule).init(allocator);
        defer rules.deinit();

        var it = std.mem.tokenize(u8, str, ",");
        while (it.next()) |token| {
            rules.append(Rule.fromString(token)) catch unreachable;
        }

        return .{ //
            .rules = rules.toOwnedSlice() catch unreachable,
            .label = label,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MultiRule) void {
        self.allocator.free(self.rules);
    }

    pub fn process(self: MultiRule, part: Part) Rule.Outcome {
        for (self.rules) |rule| {
            if (rule.process(part)) |outcome| return outcome;
        }
        unreachable;
    }

    pub fn analyze(self: MultiRule, set: *AnalysisSet) void {
        var in = set.splitRanges.get(self.label).?;
        for (self.rules) |rule| {
            // Breaks the rules abstraction, but the most simple way to handle those rules that just reutrn a single result
            if (rule.modify == ModifyRange.nop) {
                switch (rule.outcome) {
                    .Decision => |d| if (d == .Accept) set.acceptedRanges.append(in) catch unreachable,
                    .RuleDispatch => |s| {
                        set.splitRanges.put(s, in) catch unreachable;
                        set.rulesToProcess.append(s) catch unreachable;
                    },
                }
            } else {
                const splits = rule.splitPartRange(in);
                switch (rule.outcome) {
                    .Decision => |d| if (d == .Accept) set.acceptedRanges.append(splits[0]) catch unreachable,
                    .RuleDispatch => |s| {
                        set.splitRanges.put(s, splits[0]) catch unreachable;
                        set.rulesToProcess.append(s) catch unreachable;
                    },
                }
                in = splits[1];
            }
        }
    }
};

const RuleSet = struct {
    rules: std.StringHashMap(MultiRule),
    allocator: std.mem.Allocator,

    pub fn fromInput(input: [][]const u8, allocator: std.mem.Allocator) RuleSet {
        var rules = std.StringHashMap(MultiRule).init(allocator);
        for (input) |line| {
            if (line.len == 0) break;
            var it = std.mem.tokenize(u8, line, "{}");
            const label = it.next().?;
            const rule = MultiRule.fromString(it.next().?, label, allocator);
            rules.put(label, rule) catch unreachable;
        }

        return .{ //
            .rules = rules,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *RuleSet) void {
        var it = self.rules.valueIterator();
        while (it.next()) |v| v.deinit();
        self.rules.deinit();
    }

    pub fn process(self: RuleSet, part: Part) Decision {
        var currentRule = self.rules.get("in").?;

        // util.print("in -> ", .{});

        while (true) {
            switch (currentRule.process(part)) {
                .Decision => |d| {
                    // util.print("{any}\n", .{d});
                    return d;
                },
                .RuleDispatch => |s| {
                    currentRule = self.rules.get(s).?;
                    // util.print("{s} -> ", .{s});
                },
            }
        }
    }

    pub fn countValidCombinations(self: RuleSet) u64 {
        var set = AnalysisSet.init(self.allocator);
        defer set.deinit();

        set.splitRanges.put("in", PartRange{}) catch unreachable;
        set.rulesToProcess.append("in") catch unreachable;

        while (set.rulesToProcess.popOrNull()) |label| {
            const rule = self.rules.get(label).?;
            rule.analyze(&set);
        }

        var acc: u64 = 0;
        for (set.acceptedRanges.items) |r| {
            acc += r.sum();
        }
        return acc;
    }
};

const Input = struct {
    ruleSet: RuleSet,
    parts: []Part,
};

pub fn parseInput(input: [][]const u8, allocator: std.mem.Allocator) Input {
    var split: usize = for (input, 0..) |line, i| {
        if (line.len == 0) break i;
    };

    var parts = std.ArrayList(Part).init(allocator);
    defer parts.deinit();

    for (input[split + 1 .. input.len]) |line| {
        parts.append(Part.fromString(line)) catch unreachable;
    }

    return .{
        .ruleSet = RuleSet.fromInput(input[0..split], allocator),
        .parts = parts.toOwnedSlice() catch unreachable,
    };
}

pub fn task_01(ruleSet: RuleSet, parts: []Part) u32 {
    var acc: u32 = 0;
    for (parts) |part| {
        if (ruleSet.process(part) == Decision.Accept) {
            acc += part.sum();
        }
    }
    return acc;
}

pub fn task_02(ruleSet: RuleSet) u64 {
    return ruleSet.countValidCombinations();
}

test "sample input" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var input = try util.readFile("input/test/day_19.txt", allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var stuff = parseInput(input, allocator);
    defer allocator.free(stuff.parts);
    defer stuff.ruleSet.deinit();

    try std.testing.expectEqual(@as(u32, 19114), task_01(stuff.ruleSet, stuff.parts));
    try std.testing.expectEqual(@as(u64, 167409079868000), task_02(stuff.ruleSet));
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

    var stuff = parseInput(input, allocator);
    defer allocator.free(stuff.parts);
    defer stuff.ruleSet.deinit();

    util.print("Day 19 Solution 1: {}\n", .{task_01(stuff.ruleSet, stuff.parts)});
    util.print("Day 19 Solution 2: {}\n", .{task_02(stuff.ruleSet)});
}
