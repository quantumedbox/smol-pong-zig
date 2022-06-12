const std = @import("std");
const backend = @import("backend.zig");

const PAD_LENGTH = backend.WINDOW_HEIGHT / 5;

const Position = @Vector(2, u16);

const Player = struct {
    height: u16,
    points: u8 = 0,
};

const Ball = struct {
    position: Position,
    direction: enum { BottomLeft, UpLeft, UpRight, BottomRight },
};

const GameState = struct {
    is_hotseat: bool = false,
    player0: Player,
    player1: Player,

    pub fn draw(self: *@This(), context: *backend.GraphicContext) callconv(.Inline) void {
        _ = self;
        _ = context;
    }

    pub fn process(self: *@This()) callconv(.Inline) void {
        _ = self;
    }
};

const MenuState = struct {
    title_x: u16 = 0,
    title: []const u8,
    ball_pos: Position = Position { backend.WINDOW_WIDTH / 2, backend.WINDOW_HEIGHT / 2 },

    const GRAVITY = 980;

    pub fn init() callconv(.Inline) @This() {
        return .{
            .title = if (backend.rng.next() % 10 == 0) "POG GAME" else "PONG GAME",
        };
    }

    pub fn draw(self: *@This(), context: *backend.GraphicContext) callconv(.Inline) void {
        context.drawText(self.title_x, 20, self.title, 20);
        context.drawCircle(self.ball_pos[0], self.ball_pos[1], 26);
        context.drawText(0, backend.WINDOW_HEIGHT - 60, "press space to play", 20);
    }

    pub fn process(self: *@This()) callconv(.Inline) void {
        _ = self;
        _ = GRAVITY;
    }
};

var stage: union(enum) {
    menu: MenuState,
    game: GameState,
} = undefined;

pub fn init() callconv(.Inline) void {
    backend.init();
    stage = .{ .menu = MenuState.init() };
}

pub fn render(context: *backend.GraphicContext) callconv(.Inline) void {
    context.drawRect(0, 0, backend.WINDOW_WIDTH, backend.WINDOW_HEIGHT, .Black);
    switch (stage) {
        .menu => (&stage.menu).draw(context),
        .game => (&stage.game).draw(context),
    }
}

pub fn process() callconv(.Inline) void {
    switch (stage) {
        .menu => (&stage.menu).process(),
        .game => (&stage.game).process(),
    }
}
