const std = @import("std");
const win = std.os.windows;
const winapi = @import("winapi.zig");

pub const WINDOW_WIDTH = 1024;
pub const WINDOW_HEIGHT = 768;

pub const GraphicContext = struct {
    hdc: winapi.HDC,
    white_brush: winapi.HBRUSH,
    black_brush: winapi.HBRUSH,

    const Self = @This();

    const COLORREF_WHITE: win.DWORD = 0x00FFFFFF;
    const COLORREF_BLACK: win.DWORD = 0x00000000;

    pub fn init() Self {
        return .{
            .hdc = undefined,
            .white_brush = winapi.CreateSolidBrush(COLORREF_WHITE),
            .black_brush = winapi.CreateSolidBrush(COLORREF_BLACK),
        };
    }

    pub fn deinit(self: *Self) void {
        winapi.DeleteObject(self.white_brush);
        winapi.DeleteObject(self.black_brush);
    }

    pub fn drawText(self: *Self, x: u16, y: u16, text: []const u8, scale: u16) void {
        _ = scale;
        _ = winapi.SetTextColor(self.hdc, COLORREF_BLACK); // todo: Shouldn't be called every time
        // todo: Pick font, redefine scale if it's different from current
        if (winapi.TextOutA(self.hdc, x, y, @ptrCast(win.LPCSTR, &text[0]), @intCast(c_int, text.len)) == 0)
            @panic("drawText() failed");
    }

    pub fn drawRect(self: *Self, x: u16, y: u16, w: u16, h: u16, color: enum { Black, White }) void {
        // todo: Shouldn't be called every time
        _ = winapi.SelectObject(self.hdc, switch (color) {
            .White => self.white_brush,
            .Black => self.black_brush});
        if (winapi.Rectangle(self.hdc, x, y, x + w, y + h) == 0)
            @panic("Rectangle() failed");
    }

    pub fn drawCircle(self: *Self, x: u16, y: u16, radius: u16) void {
        _ = winapi.SelectObject(self.hdc, self.white_brush); // todo: Shouldn't be called every time
        const half_radius = radius / 2;
        if (winapi.Ellipse(self.hdc, x - half_radius, y - half_radius, x + half_radius, y + half_radius) == 0)
            @panic("Ellipse() failed");
    }
};

pub fn getTimestamp() u32 {
    return winapi.GetTickCount();
}
