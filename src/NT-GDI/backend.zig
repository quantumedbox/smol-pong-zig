const std = @import("std");
const builtin = @import("builtin");
const winapi = @import("winapi.zig");

pub const GraphicContext = struct {
    hdc: winapi.HDC,

    pub fn init() @This() {
        return .{
            .hdc = undefined,
        };
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    // todo: Pick font, redefine scale if it's different from current
    pub fn drawText(self: *@This(), x: i16, y: i16, text: []const u8, scale: enum { Big, Small }) void {
        _ = scale;
        if (winapi.TextOutA(self.hdc, x, y, @ptrCast(winapi.LPCSTR, &text[0]), @intCast(c_int, text.len)) == 0)
            panicFmt("drawText() failed", .{});
    }

    pub fn getTextDimensions(self: *@This(), text: []const u8, scale: enum { Big, Small }) [2]i16 {
        _ = scale;
        var size: winapi.SIZE = undefined;
        if (winapi.GetTextExtentPoint32A(self.hdc, @ptrCast(winapi.LPCSTR, &text[0]), @intCast(c_int, text.len), &size) == 0)
            panicFmt("GetTextExtentPoint32A() failed", .{});
        return [2]i16{ @intCast(i16, size.cx), @intCast(i16, size.cy) };
    }

    pub fn drawRect(self: *@This(), x: i16, y: i16, w: i16, h: i16) void {
        // todo: Shouldn't be called every time
        if (winapi.Rectangle(self.hdc, x, y, x + w, y + h) == 0)
            panicFmt("Rectangle() failed", .{});
    }

    pub fn drawCircle(self: *@This(), x: i16, y: i16, radius: i16) void {
        const half_radius = @divTrunc(radius, 2);
        if (winapi.Ellipse(self.hdc, x - half_radius, y - half_radius, x + half_radius, y + half_radius) == 0)
            panicFmt("Ellipse() failed", .{});
    }
};

pub fn getTimestamp() u32 {
    return winapi.GetTickCount();
}

pub fn panicFmt(fmt: []const u8, args: anytype) void {
    if (builtin.mode == .Debug) {
        std.debug.panic(fmt, args);
    }
}
