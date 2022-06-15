const std = @import("std");
const builtin = @import("builtin");
const impl = switch (builtin.os.tag) {
    .windows => @import("nt-gdi/backend.zig"),
    else => @panic("Unimplemented backend"),
};
usingnamespace impl;
const game = @import("game.zig");

// Milliseconds per each `process` frame
pub const PROCESS_FRAME_TIME = 17;
pub const PROCESS_FRAME_TIME_LIMIT = 1000;

// todo: Some backends might guarantee the dimensions at comptime, should be potentially const
pub var window_width: i16 = undefined;
pub var window_height: i16 = undefined;
pub var window_half_width: i16 = undefined;
pub var window_half_height: i16 = undefined;

// warn! Is only valid in duration of `render` callback
pub var graphic_context: impl.GraphicContext = undefined;
// warn! Is only valid in duration of `process` callback
pub var keymap: struct {
    players: [2][2]i16 = [2][2]i16{ .{0, 0}, .{0, 0} }, // 2 players, 2 states: is_up_pressed, is_down_pressed
} = .{};
pub var rng: Rng = undefined;

var time_last: u32 = 0;
pub var frame_count: u16 = 0; // Wrapping counter, useful in `draw`

pub const Vec2 = [2]i16;

/// Xorshift32
const Rng = struct {
    state: u32,

    pub fn next(self: *@This()) u32 {
        var x = self.state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= 5;
        self.state = x;
        return x;
    }

    pub fn intInRange(self: *@This(), comptime T: type, min: T, max: T) T {
        return std.math.clamp(@intCast(T, self.next()), min, max);
    }
};

pub fn init() void {
    const time = impl.getTimestamp();
    time_last = time;
    rng = Rng { .state = time };
    game.init();
}

pub fn deinit() void {

}

pub fn process() void {
    var current_time = impl.getTimestamp();
    if (current_time - time_last >= PROCESS_FRAME_TIME_LIMIT)
        time_last = current_time - PROCESS_FRAME_TIME_LIMIT;
    while (current_time - time_last >= PROCESS_FRAME_TIME) {
        game.process();
        frame_count +%= 1;
        time_last += PROCESS_FRAME_TIME;
    }
}
