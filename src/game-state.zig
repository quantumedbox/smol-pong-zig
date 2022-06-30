const std = @import("std");
const backend = @import("backend.zig");

is_hotseat: bool = false,
players: [2]Player,
ball: Ball,

pub fn init(mode: enum { WithBot, Hotseat }) @This() {
    return .{
        .is_hotseat = switch (mode) { .Hotseat => true, .WithBot => false },
        .players = [2]Player{ Player.init(), Player.init() },
        .ball = Ball.init(0),
    };
}

pub fn draw(self: *@This()) void {
    backend.graphic_context.drawRect(0, self.players[0].y, Player.WIDTH, Player.HEIGHT);
    backend.graphic_context.drawRect(backend.window_width - Player.WIDTH, self.players[1].y, Player.WIDTH, Player.HEIGHT);
    backend.graphic_context.drawCircle(self.ball.pos[0], self.ball.pos[1], Ball.RADIUS);

    var buf: [3]u8 = undefined;
    backend.graphic_context.drawText(0, 0, pointsToText(&buf, self.players[0].points), .Big);
    const slice = pointsToText(&buf, self.players[1].points);
    const dims = backend.graphic_context.getTextDimensions(slice, .Big);
    backend.graphic_context.drawText(backend.window_width - dims[0], 0, slice, .Big);
}

pub fn process(self: *@This()) void {
    // Player pads
    for (self.players) |*player, i| {
        if (i == 1 and !self.is_hotseat) {
            player.target_y += Player.SPEED * (@as(i16, @boolToInt(self.ball.pos[1] > (player.target_y + Player.HEIGHT / 2))) * 2 - 1);
        } else {
            player.target_y += Player.SPEED * (backend.keymap.players[i][1] - backend.keymap.players[i][0]);
        }
        player.target_y = std.math.clamp(player.target_y, 0, backend.window_height - Player.HEIGHT);
        player.y += @divTrunc(player.target_y - player.y, 4);
    }

    // Process ball
    self.ball.process();

    // Passing further than pad is considered a `goal`, this way we dont need to care about ball collision with top and bottom edge, as it's a lose anyway
    for (self.players) |*player, i| {
        if (i == 0) {
            if ((self.ball.left_extend) > Player.WIDTH)
                continue;
        } else {
            if ((self.ball.right_extend) < backend.window_width - Player.WIDTH)
                continue;
        }
        // Brain fart
        if (isSegmentContained(self.ball.up_extend, self.ball.bottom_extend, player.y, player.y + Player.HEIGHT)) {
            self.ball.dir[0] = -(@intCast(i8, i) * 2 - 1);
            self.ball.speed += 1;
            self.ball.pos[0] = if (i == 0)
                Player.WIDTH + Ball.RADIUS / 2
            else
                backend.window_width - Player.WIDTH - Ball.RADIUS / 2;
        } else {
            self.players[1 - i].points += 1;
            self.ball = Ball.init(backend.rng.intInRange(i16, -32, 32));
            for (self.players) |*player_| {
                player_.y = backend.window_half_height;
                player_.target_y = backend.window_half_height;
            }
            return;
        }
    }

    // Bounce from borders
    if ((self.ball.bottom_extend) > backend.window_height) {
        self.ball.dir[1] *= -1;
        self.ball.pos[1] = backend.window_height - Ball.RADIUS / 2;
    } else if ((self.ball.up_extend) < 0) {
        self.ball.dir[1] *= -1;
        self.ball.pos[1] = Ball.RADIUS / 2;
    }
}

const Player = struct {
    y: i16,
    target_y: i16,
    points: u8 = 0,

    // todo: It might be better to delegate sizes to backends, as gameplay might be affected by specific resolutions that are available
    const WIDTH = 24;
    const HEIGHT = 100;
    const SPEED = 8;

    pub fn init() @This() {
        return .{
            .y = backend.window_half_height,
            .target_y = backend.window_half_height,
        };
    }
};

const Ball = struct {
    pos: backend.Vec2,
    dir: [2]i8 = [2]i8{ -1, -1 }, // direction mask
    speed: i8 = 4,
    left_extend: i16,
    right_extend: i16,
    up_extend: i16,
    bottom_extend: i16,

    const RADIUS = 24;

    pub fn init(offset: i16) @This() {
        return .{
            .pos = backend.Vec2 { backend.window_half_width, backend.window_half_height },
            .left_extend = backend.window_half_width - offset - Ball.RADIUS / 2,
            .right_extend = backend.window_half_width + offset + Ball.RADIUS / 2,
            .up_extend = backend.window_half_height - offset - Ball.RADIUS / 2,
            .bottom_extend = backend.window_half_height + offset + Ball.RADIUS / 2,
        };
    }

    pub fn process(self: *@This()) void {
        self.pos[0] += self.speed * self.dir[0];
        self.pos[1] += self.speed * self.dir[1];
        self.left_extend = self.pos[0] - Ball.RADIUS / 2;
        self.right_extend = self.pos[0] + Ball.RADIUS / 2;
        self.up_extend = self.pos[1] - Ball.RADIUS / 2;
        self.bottom_extend = self.pos[1] + Ball.RADIUS / 2;
    }
};

fn pointsToText(buf: *[3]u8, val: u8) []const u8 {
    var a = val;
    var index: usize = buf.len;
    while (true) {
        const digit = a % 10;
        index -= 1;
        buf[index] = std.fmt.digitToChar(digit, .lower);
        a /= 10;
        if (a == 0) break;
    }
    return buf[index..buf.len];
}

fn isSegmentContained(ax: i16, ay: i16, bx: i16, by: i16) bool {
    return (bx <= ax and ax <= by) or (bx <= ay and ay <= by);
}
