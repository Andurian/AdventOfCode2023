pub const State = enum {
    Unknown,
    Operational,
    Damaged,

    pub fn fromChar(c: u8) State {
        return switch (c) {
            '?' => State.Unknown,
            '.' => State.Operational,
            '#' => State.Damaged,
            else => unreachable,
        };
    }

    pub fn toChar(s: State) u8 {
        return switch (s) {
            State.Unknown => '?',
            State.Operational => '.',
            State.Damaged => '#',
        };
    }

    pub fn match(lhs: State, rhs: State) bool {
        return lhs == State.Unknown or rhs == State.Unknown or rhs == lhs;
    }
};
