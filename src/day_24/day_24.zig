const std = @import("std");
const util = @import("util");

const Float = f64;
const Vec3 = @Vector(3, Float);
const Vec2 = @Vector(2, Float);

const Trajectory = struct {
    pos: Vec3,
    dir: Vec3,

    pub fn fromInput(line: []const u8) Trajectory {
        var it = std.mem.tokenize(u8, line, "@, ");
        const px = std.fmt.parseFloat(Float, it.next().?) catch unreachable;
        const py = std.fmt.parseFloat(Float, it.next().?) catch unreachable;
        const pz = std.fmt.parseFloat(Float, it.next().?) catch unreachable;

        const vx = std.fmt.parseFloat(Float, it.next().?) catch unreachable;
        const vy = std.fmt.parseFloat(Float, it.next().?) catch unreachable;
        const vz = std.fmt.parseFloat(Float, it.next().?) catch unreachable;

        return .{ .pos = .{ px, py, pz }, .dir = .{ vx, vy, vz } };
    }
};

pub fn norm(comptime len: comptime_int, vec: @Vector(len, Float)) Float {
    var res: Float = @reduce(.Add, vec * vec);
    return std.math.sqrt(res);
}

pub fn normalized(comptime len: comptime_int, vec: @Vector(len, Float)) @Vector(len, Float) {
    return vec / @as(@Vector(len, Float), @splat(norm(len, vec)));
}

pub fn dot(comptime len: comptime_int, vec1: @Vector(len, Float), vec2: @Vector(len, Float)) Float {
    return @reduce(.Add, vec1 * vec2);
}

pub fn angle(comptime len: comptime_int, vec1: @Vector(len, Float), vec2: @Vector(len, Float)) Float {
    const d = dot(len, vec1, vec2);
    const n1 = norm(len, vec1);
    const n2 = norm(len, vec2);
    const n = n1 * n2;
    return std.math.acos(d / n);
}

pub fn Intersection(comptime len: comptime_int) type {
    return struct {
        p: @Vector(len, Float),
        x1: Float,
        x2: Float,
    };
}

pub fn areParallel(comptime len: comptime_int, v1: @Vector(len, Float), v2: @Vector(len, Float)) bool {
    const s = dot(len, v1, v2);
    return s * s == @reduce(.Add, v1 * v1) * @reduce(.Add, v2 * v2);
}

pub fn intersectTrajectories2D(t1: Trajectory, t2: Trajectory) ?Intersection(2) {
    const p1 = Vec2{ t1.pos[0], t1.pos[1] };
    const p2 = Vec2{ t2.pos[0], t2.pos[1] };

    var v1 = Vec2{ t1.dir[0], t1.dir[1] };
    var v2 = Vec2{ t2.dir[0], t2.dir[1] };

    //util.print("{any} - {any} -> {}\n", .{ v1, v2, angle(2, v1, v2) });
    if (areParallel(2, v1, v2)) return null;

    v1 = normalized(2, v1);
    v2 = normalized(2, v2);

    const d = p2 - p1;

    const a = dot(2, v1, v2);
    const b = dot(2, d, v1);
    const c = dot(2, d - @as(Vec2, @splat(b)) * v1, v2);

    const x2 = 1.0 / (a * a - 1) * c;
    const x1 = dot(2, d + @as(Vec2, @splat(x2)) * v2, v1);

    const p = @as(Vec2, @splat(0.5)) * (p1 + @as(Vec2, @splat(x1)) * v1 + p2 + @as(Vec2, @splat(x2)) * v2);
    return .{ .p = p, .x1 = x1, .x2 = x2 };
}

pub fn isValidIntersection(i: Intersection(2), min: Float, max: Float) bool {
    return i.x1 >= 0 and i.x2 >= 0 and i.p[0] >= min and i.p[0] <= max and i.p[1] >= min and i.p[1] <= max;
}

pub fn task_01(trajectories: []Trajectory, min: Float, max: Float) u64 {
    var acc: u64 = 0;

    var i: usize = 0;
    while (i < trajectories.len) : (i += 1) {
        const t1 = trajectories[i];
        var j: usize = i + 1;
        while (j < trajectories.len) : (j += 1) {
            const t2 = trajectories[j];
            if (intersectTrajectories2D(t1, t2)) |intersection| {
                if (isValidIntersection(intersection, min, max)) acc += 1;
            }
        }
    }

    return acc;
}

//task 2: Z3 Java Script
// const qx = Z3.Int.const('qx');
// const qy = Z3.Int.const('qy');
// const qz = Z3.Int.const('qz');

// const dx = Z3.Int.const('dx');
// const dy = Z3.Int.const('dy');
// const dz = Z3.Int.const('dz');

// const a = Z3.Int.const('a');
// const b = Z3.Int.const('b');
// const c = Z3.Int.const('c');

// Z3.solve(
//     qx.add(a.mul(dx)).eq(a.mul(64).add(232488932265751)),
//     qy.add(a.mul(dy)).eq(a.mul(273).add(93844132799095)),
//     qz.add(a.mul(dz)).eq(a.mul(119).add(203172424390144)),

//     qx.add(b.mul(dx)).eq(b.mul(14).add(258285813391475)),
//     qy.add(b.mul(dy)).eq(b.mul(-10).add(225317967801013)),
//     qz.add(b.mul(dz)).eq(b.mul(-22).add(306162724914014)),

//     qx.add(c.mul(dx)).eq(c.mul(-182).add(377519381672953)),
//     qy.add(c.mul(dy)).eq(c.mul(-80).add(343737262245611)),
//     qz.add(c.mul(dz)).eq(c.mul(-373).add(485395777725108)),
// );

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input = try util.readFile(args[1], allocator);
    defer allocator.free(input);
    defer for (input) |i| allocator.free(i);

    var trajectories = std.ArrayList(Trajectory).init(allocator);
    defer trajectories.deinit();

    for (input) |line| {
        trajectories.append(Trajectory.fromInput(line)) catch unreachable;
    }

    util.print("Day 24 Solution 1: {}\n", .{task_01(trajectories.items, 200000000000000, 400000000000000)});
}
