const Self = @This();

size: i32,
start: i32,

pub fn behindLast(self: Self) i32 {
    return self.start + self.size;
}

pub fn last(self: Self) i32 {
    return self.behindLast() - 1;
}

pub fn contains(self: Self, other: Self) bool {
    return other.start >= self.start and other.last() <= self.last();
}

pub fn isContainedInAny(self: Self, list: []const Self) bool {
    for (list) |l| if (l.contains(self)) return true;
    return false;
}
