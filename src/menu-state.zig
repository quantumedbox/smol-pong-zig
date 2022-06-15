const std = @import("std");
const backend = @import("backend.zig");
const game = @import("game.zig");

title: []const u8,
ball_pos: backend.Vec2,
ball_velocity: backend.Vec2 = backend.Vec2 { -10, 0 },

const HINT_TEXT = "Press 'A' to play with bot, 'S' to play with other player.";
const GRAVITY = 1; // per process tick
const BALL_RADIUS = 26;

pub fn init() @This() {
    return .{
        .ball_pos = backend.Vec2 { backend.window_half_width, backend.window_half_height },
        .title = if (backend.rng.next() % 10 == 0) "POG GAME" else "PONG GAME",
    };
}

pub fn draw(self: *@This()) void {
    const title_dims = backend.graphic_context.getTextDimensions(self.title, 20); // todo: Can we escape getting it every time?
    std.debug.assert(title_dims[0] <= backend.window_width);
    const range = backend.window_width - title_dims[0];
    const a = @intCast(u8, backend.frame_count % 256);
    const x = @divTrunc(range, 127) * (a - (((a & 1 << 7) >> 7) * (a - 128)) * 2);
    backend.graphic_context.drawText(x, 0, self.title, 20);
    backend.graphic_context.drawCircle(self.ball_pos[0], self.ball_pos[1], 26);
    const hint_dims = backend.graphic_context.getTextDimensions(HINT_TEXT, 15); // todo: Can we escape getting it every time?
    backend.graphic_context.drawText(0, backend.window_height - hint_dims[1], HINT_TEXT, 15);
}

pub fn process(self: *@This()) void {
    self.ball_velocity[1] += GRAVITY;
    self.ball_pos[0] += self.ball_velocity[0];
    self.ball_pos[1] += self.ball_velocity[1];
    // todo: Reuse collision code that is used in GameState
    if ((self.ball_pos[1] + BALL_RADIUS / 2) >= backend.window_height) {
        self.ball_velocity[1] *= -1;
        self.ball_pos[1] = backend.window_height - BALL_RADIUS / 2 - 1;
    }
    if ((self.ball_pos[0] - BALL_RADIUS / 2) <= 0) {
        self.ball_velocity[0] *= -1;
        self.ball_pos[0] = BALL_RADIUS / 2 + 1;
    }
    if ((self.ball_pos[0] + BALL_RADIUS / 2) >= backend.window_width) {
        self.ball_velocity[0] *= -1;
        self.ball_pos[0] = backend.window_width - BALL_RADIUS / 2 - 1;
    }

    if (backend.keymap.players[0][0] == 1)
        game.stage = .{ .game = game.GameState.init(.WithBot) };
    if (backend.keymap.players[0][1] == 1)
        game.stage = .{ .game = game.GameState.init(.Hotseat) };
}
