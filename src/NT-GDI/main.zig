const std = @import("std");
const builtin = @import("builtin");
const win = std.os.windows;
const winapi = @import("winapi.zig");
const backend = @import("backend");
const game = @import("game");

const REQUESTED_WINDOW_WIDTH = 1024;
const REQUESTED_WINDOW_HEIGHT = 768;
const TIMER_ID = 1000;

pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?*anyopaque, pCmdLine: win.PWSTR, nCmdShow: c_int) callconv(win.WINAPI) c_int {
    // todo: Breaks when used other subsystem besides .Windows?
    if (builtin.target.cpu.arch == .x86_64) {
        @setAlignStack(16);
    } else {
        @setAlignStack(4);
    }

    _ = hPrevInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    const className = &[_:0]u16{0x20};
    const class = win.user32.WNDCLASSEXW {
        .lpszClassName = className,
        .lpfnWndProc = messageCallback,
        .hInstance = hInstance,
        .style = win.user32.CS_OWNDC | win.user32.CS_HREDRAW | win.user32.CS_VREDRAW,
        .hIcon = null,
        .hIconSm = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
    };

    _ = win.user32.registerClassExW(&class) catch unreachable;

    const style_flags = comptime (@as(u32, win.user32.WS_OVERLAPPEDWINDOW) & ~@as(u32, win.user32.WS_MAXIMIZEBOX) & ~@as(u32, win.user32.WS_THICKFRAME)) | @as(u32, win.user32.WS_CLIPCHILDREN);
    const window = win.user32.createWindowExW(
        0,
        className,
        &[_:0]u16{0x00},
        style_flags,
        win.user32.CW_USEDEFAULT, win.user32.CW_USEDEFAULT,
        REQUESTED_WINDOW_WIDTH, REQUESTED_WINDOW_HEIGHT,
        null, null, hInstance, null
    ) catch @panic("cannot create window");

    _ = win.user32.showWindow(window, 1);

    // todo: Kinda shitty
    const hwnd = @ptrCast(winapi.HWND, @alignCast(@alignOf(winapi.HWND), window));

    if (winapi.SetTimer(hwnd, TIMER_ID, 0, null) == 0)
        @panic("SetTimer() failed");

    messageloop: while (true) {
        var msg: win.user32.MSG = undefined;
        if (win.user32.getMessageW(&msg, null, 0, 0)) {
            _ = win.user32.translateMessage(&msg);
            _ = win.user32.dispatchMessageW(&msg);
        } else |err| switch (err) {
            error.Quit => break :messageloop,
            else => @panic("error getting message in event loop"),
        }
    }

    return 0;
}

fn messageCallback(hwnd_: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) callconv(win.WINAPI) win.LRESULT {
    // todo: Kinda shitty
    const hwnd = @ptrCast(winapi.HWND, @alignCast(@alignOf(winapi.HWND), hwnd_));

    switch (uMsg) {
        win.user32.WM_CREATE => {
            backend.init();
            backend.graphic_context = backend.GraphicContext.init();
            var window_rect: winapi.RECT = undefined;
            if (winapi.GetClientRect(hwnd, &window_rect) == 0)
                @panic("GetClientRect() failed");
            backend.window_width = @intCast(i16, window_rect.right - 1);
            backend.window_height = @intCast(i16, window_rect.bottom - 1);
            backend.window_half_width = @divTrunc(backend.window_width, 2);
            backend.window_half_height = @divTrunc(backend.window_height, 2);
        },
        win.user32.WM_TIMER => {
            if (wParam == TIMER_ID) {
                backend.process();
                if (winapi.InvalidateRect(hwnd, null, win.FALSE) == 0)
                    @panic("InvalidateRect() failed");
            }
        },
        win.user32.WM_PAINT => {
            var ps: winapi.PAINTSTRUCT = undefined; 
            const hdc = winapi.BeginPaint(hwnd, &ps);
            const mem_dc = winapi.CreateCompatibleDC(hdc);
            var window_rect: winapi.RECT = undefined;
            if (winapi.GetClientRect(hwnd, &window_rect) == 0)
                @panic("GetClientRect() failed");
            const bmp = winapi.CreateCompatibleBitmap(hdc, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top);
            const oldBmp = winapi.SelectObject(mem_dc, bmp);
            backend.graphic_context.hdc = mem_dc;
            game.render();
            if (winapi.BitBlt(hdc, 0, 0, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top, mem_dc, 0, 0, winapi.SRCCOPY) == 0)
                @panic("BitBlt() failed");
            if (winapi.SelectObject(mem_dc, oldBmp) == null)
                @panic("SelectObject() failed");
            if (winapi.DeleteObject(bmp) == 0)
                @panic("DeleteObject() failed");
            if (winapi.DeleteObject(mem_dc) == 0)
                @panic("DeleteObject() failed");
            _ = winapi.EndPaint(hwnd, &ps);
        },
        win.user32.WM_KEYDOWN => switch (wParam) {
            'W' => backend.keymap.players[0][0] = 1,
            'S' => backend.keymap.players[0][1] = 1,
            winapi.VK_UP => backend.keymap.players[1][0] = 1,
            winapi.VK_DOWN => backend.keymap.players[1][1] = 1,
            else => {},
        },
        win.user32.WM_KEYUP => switch (wParam) {
            'W' => backend.keymap.players[0][0] = 0,
            'S' => backend.keymap.players[0][1] = 0,
            winapi.VK_UP => backend.keymap.players[1][0] = 0,
            winapi.VK_DOWN => backend.keymap.players[1][1] = 0,
            else => {},
        },
        win.user32.WM_DESTROY => {
            backend.deinit();
            if (winapi.KillTimer(hwnd, TIMER_ID) == 0)
                @panic("KillTimer() failed");
            win.user32.postQuitMessage(0);
        },
        else => return win.user32.defWindowProcW(hwnd_, uMsg, wParam, lParam),
    }
    return 0;
}
