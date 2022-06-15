const std = @import("std");
const win = std.os.windows;
const winapi = @import("winapi.zig");

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

    // todo: Pick font, redefine scale if it's different from current
    // todo: Use enum { Big, Small } instead? As we dont really need to have other options here
    pub fn drawText(self: *Self, x: i16, y: i16, text: []const u8, scale: i16) void {
        _ = scale;
        _ = winapi.SetTextColor(self.hdc, COLORREF_WHITE); // todo: Shouldn't be called every time
        _ = winapi.SetBkColor(self.hdc, COLORREF_BLACK);
        if (winapi.TextOutA(self.hdc, x, y, @ptrCast(win.LPCSTR, &text[0]), @intCast(c_int, text.len)) == 0)
            @panic("drawText() failed");
    }

    // todo: Fetch all dimensions on initialization
    //       All usable strings could be stored in global registry, so that this impl would be aware of what it should cache
    pub fn getTextDimensions(self: *Self, text: []const u8, scale: i16) [2]i16 {
        _ = scale;
        var size: winapi.SIZE = undefined;
        if (winapi.GetTextExtentPoint32A(self.hdc, @ptrCast(win.LPCSTR, &text[0]), @intCast(c_int, text.len), &size) == 0)
            @panic("GetTextExtentPoint32A() failed");
        return [2]i16{ @intCast(i16, size.cx), @intCast(i16, size.cy) };
    }

    pub fn drawRect(self: *Self, x: i16, y: i16, w: i16, h: i16, color: enum { Black, White }) void {
        // todo: Shouldn't be called every time
        _ = winapi.SelectObject(self.hdc, switch (color) {
            .White => self.white_brush,
            .Black => self.black_brush});
        if (winapi.Rectangle(self.hdc, x, y, x + w, y + h) == 0)
            @panic("Rectangle() failed");
    }

    pub fn drawCircle(self: *Self, x: i16, y: i16, radius: i16) void {
        _ = winapi.SelectObject(self.hdc, self.white_brush); // todo: Shouldn't be called every time
        const half_radius = @divTrunc(radius, 2);
        if (winapi.Ellipse(self.hdc, x - half_radius, y - half_radius, x + half_radius, y + half_radius) == 0)
            @panic("Ellipse() failed");
    }
};

pub fn getTimestamp() u32 {
    return winapi.GetTickCount();
}
