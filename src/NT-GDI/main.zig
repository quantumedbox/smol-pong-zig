const std = @import("std");
const win = std.os.windows;
const winapi = @import("winapi.zig");

const backend = @import("backend");
const game = @import("game");

const makeWide = std.unicode.utf8ToUtf16LeStringLiteral;

pub export fn wWinMain(hInstance: win.HINSTANCE, hPrevInstance: ?*anyopaque, pCmdLine: win.PWSTR, nCmdShow: c_int) callconv(win.WINAPI) c_int {
    @setAlignStack(16);

    _ = hPrevInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    const className = comptime makeWide(".");
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

    const style_flags = comptime @as(u32, win.user32.WS_OVERLAPPEDWINDOW) & ~@as(u32, win.user32.WS_MAXIMIZEBOX) & ~@as(u32, win.user32.WS_THICKFRAME);
    const window = win.user32.createWindowExW(
        0,
        className,
        comptime makeWide(""),
        style_flags,
        win.user32.CW_USEDEFAULT, win.user32.CW_USEDEFAULT,
        backend.WINDOW_WIDTH, backend.WINDOW_HEIGHT,
        null, null, hInstance, null
    ) catch @panic("cannot create window");

    _ = win.user32.showWindow(window, 1);

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

fn messageCallback(hwnd: win.HWND, uMsg: win.UINT, wParam: win.WPARAM, lParam: win.LPARAM) callconv(win.WINAPI) win.LRESULT {
    switch (uMsg) {
        win.user32.WM_CREATE => {
            game.init();
        },
        win.user32.WM_PAINT => {
            const static = struct {
                pub var graphic_context: ?backend.GraphicContext = null;
            };
            if (static.graphic_context == null) {
                static.graphic_context = backend.GraphicContext.init();
            }
            var ps: winapi.PAINTSTRUCT = undefined; 
            (static.graphic_context orelse unreachable).hdc = winapi.BeginPaint(cAlign(winapi.HWND, hwnd), &ps);
            game.render(&(static.graphic_context orelse unreachable));
            _ = winapi.EndPaint(cAlign(winapi.HWND, hwnd), &ps);
        },
        win.user32.WM_DESTROY => {
            backend.deinit();
            win.user32.postQuitMessage(0);
        },
        else => return win.user32.defWindowProcW(hwnd, uMsg, wParam, lParam),
    }
    return 0;
}

// todo: There's probably way to skip that mess
fn cAlign(comptime T: type, ptr: anytype) T {
    comptime {
        std.debug.assert(@sizeOf(T) == @sizeOf(@TypeOf(ptr)));
        std.debug.assert(@alignOf(T) == @alignOf(@TypeOf(ptr)));
    }
    return @ptrCast(T, @alignCast(@alignOf(T), ptr));
}
