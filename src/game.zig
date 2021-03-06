const std = @import("std");
const backend = @import("backend.zig");
pub const GameState = @import("game-state.zig");
pub const MenuState = @import("menu-state.zig");

pub var stage: union(enum) {
    menu: MenuState,
    game: GameState,
} = undefined;

pub fn init() void {
    stage = .{ .menu = MenuState.init() };
}

pub fn render() void {
    switch (stage) {
        .menu => stage.menu.draw(),
        .game => stage.game.draw(),
    }
}

pub fn process() void {
    switch (stage) {
        .menu => stage.menu.process(),
        .game => stage.game.process(),
    }
}
