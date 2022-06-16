const builtin = @import("builtin");
const winapi = @import("winapi.zig");
const backend = @import("backend");
const game = @import("game");

const REQUESTED_WINDOW_WIDTH = 1024;
const REQUESTED_WINDOW_HEIGHT = 768;
const TIMER_ID = 1000;

pub const WINAPI = if (builtin.target.cpu.arch == .i386) .Stdcall else .C;

// note: This breaks async, stack trace and possibly other things
pub export fn WinMainCRTStartup() callconv(WINAPI) noreturn {
    // todo: Breaks when used other subsystem besides .Windows?
    if (builtin.target.cpu.arch == .x86_64) {
        @setAlignStack(16);
    } else {
        @setAlignStack(4);
    }
    WinMain();
    winapi.ExitProcess(0);
}

fn WinMain() callconv(.Inline) void {
    const hInstance = @intToPtr(winapi.HINSTANCE, 0x400000);

    const className = [_:0]u8{0x20, 0x00};
    const class = winapi.WNDCLASSA {
        .lpszClassName = &className,
        .lpfnWndProc = messageCallback,
        .hInstance = hInstance,
        .style = winapi.CS_OWNDC | winapi.CS_HREDRAW | winapi.CS_VREDRAW,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
    };

    if (winapi.RegisterClassA(&class) == 0)
        backend.panicFmt("RegisterClassExA() failed", .{});

    const style_flags = comptime (@as(u32, winapi.WS_OVERLAPPEDWINDOW) & ~@as(u32, winapi.WS_MAXIMIZEBOX) & ~@as(u32, winapi.WS_THICKFRAME)) | @as(u32, winapi.WS_CLIPCHILDREN);
    const window = winapi.CreateWindowA(
        &className,
        null,
        style_flags,
        winapi.CW_USEDEFAULT, winapi.CW_USEDEFAULT,
        REQUESTED_WINDOW_WIDTH, REQUESTED_WINDOW_HEIGHT,
        null, null, null, null
    );
    if (window == null)
        backend.panicFmt("CreateWindowExA() failed", .{});

    _ = winapi.ShowWindow(window, 1);

    if (winapi.SetTimer(window, TIMER_ID, 0, null) == 0)
        backend.panicFmt("SetTimer() failed", .{});

    while (true) {
        var msg: winapi.MSG = undefined;
        switch (winapi.GetMessageA(&msg, null, 0, 0)) {
            0 => break, // Quit message
            -1 => backend.panicFmt("GetMessageA() errored", .{}),
            else => {
                _ = winapi.TranslateMessage(&msg);
                _ = winapi.DispatchMessageA(&msg);
            }
        }
    }
}

fn messageCallback(hwnd_: winapi.HWND, uMsg: winapi.UINT, wParam: winapi.WPARAM, lParam: winapi.LPARAM) callconv(WINAPI) winapi.LRESULT {
    if (builtin.target.cpu.arch == .x86_64) {
        @setAlignStack(16);
    } else {
        @setAlignStack(4);
    }

    // todo: Kinda shitty
    const hwnd = @ptrCast(winapi.HWND, @alignCast(@alignOf(winapi.HWND), hwnd_));

    switch (uMsg) {
        winapi.WM_CREATE => {
            backend.init();
            backend.graphic_context = backend.GraphicContext.init();
            var window_rect: winapi.RECT = undefined;
            if (winapi.GetClientRect(hwnd, &window_rect) == 0)
                backend.panicFmt("GetClientRect() failed", .{});
            backend.window_width = @intCast(i16, window_rect.right - 1);
            backend.window_height = @intCast(i16, window_rect.bottom - 1);
            backend.window_half_width = @divTrunc(backend.window_width, 2);
            backend.window_half_height = @divTrunc(backend.window_height, 2);
        },
        winapi.WM_TIMER => {
            if (wParam == TIMER_ID) {
                backend.process();
                if (winapi.InvalidateRect(hwnd, null, winapi.FALSE) == 0)
                    backend.panicFmt("InvalidateRect() failed", .{});
            }
        },
        winapi.WM_PAINT => {
            var ps: winapi.PAINTSTRUCT = undefined; 
            const hdc = winapi.BeginPaint(hwnd, &ps);
            const mem_dc = winapi.CreateCompatibleDC(hdc);
            var window_rect: winapi.RECT = undefined;
            if (winapi.GetClientRect(hwnd, &window_rect) == 0)
                backend.panicFmt("GetClientRect() failed", .{});
            const bmp = winapi.CreateCompatibleBitmap(hdc, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top);
            const oldBmp = winapi.SelectObject(mem_dc, bmp);
            backend.graphic_context.hdc = mem_dc;
            game.render();
            if (winapi.BitBlt(hdc, 0, 0, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top, mem_dc, 0, 0, winapi.SRCCOPY) == 0)
                backend.panicFmt("BitBlt() failed", .{});
            if (winapi.SelectObject(mem_dc, oldBmp) == null)
                backend.panicFmt("SelectObject() failed", .{});
            if (winapi.DeleteObject(bmp) == 0)
                backend.panicFmt("DeleteObject() failed", .{});
            if (winapi.DeleteObject(mem_dc) == 0)
                backend.panicFmt("DeleteObject() failed", .{});
            _ = winapi.EndPaint(hwnd, &ps);
        },
        winapi.WM_KEYDOWN => switch (wParam) {
            'W' => backend.keymap.players[0][0] = 1,
            'S' => backend.keymap.players[0][1] = 1,
            winapi.VK_UP => backend.keymap.players[1][0] = 1,
            winapi.VK_DOWN => backend.keymap.players[1][1] = 1,
            else => {},
        },
        winapi.WM_KEYUP => switch (wParam) {
            'W' => backend.keymap.players[0][0] = 0,
            'S' => backend.keymap.players[0][1] = 0,
            winapi.VK_UP => backend.keymap.players[1][0] = 0,
            winapi.VK_DOWN => backend.keymap.players[1][1] = 0,
            else => {},
        },
        winapi.WM_DESTROY => {
            if (winapi.KillTimer(hwnd, TIMER_ID) == 0)
                backend.panicFmt("KillTimer() failed", .{});
            winapi.PostQuitMessage(0);
        },
        else => return winapi.DefWindowProcW(hwnd_, uMsg, wParam, lParam),
    }
    return 0;
}
