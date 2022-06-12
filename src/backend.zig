const builtin = @import("builtin");
const impl = switch (builtin.os.tag) {
    .windows => @import("NT-GDI/backend.zig"),
    else => @panic("Unimplemented backend"),
};
usingnamespace impl;

pub var rng: Rng = undefined;

// Xorshift32
const Rng = struct {
    state: u32,

    const Self = @This();

    pub fn next(self: *Self) u32 {
        var x = self.state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= 5;
        self.state = x;
        return x;
    }
};

pub fn init() callconv(.Inline) void {
    rng = Rng {
        .state = impl.getTimestamp(),
    };
}

pub fn deinit() callconv(.Inline) void {

}
