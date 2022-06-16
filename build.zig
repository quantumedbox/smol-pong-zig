const std = @import("std");
const builtin = @import("builtin");

const default_target = std.zig.CrossTarget {
    .cpu_arch = builtin.target.cpu.arch,
    .os_tag = builtin.target.os.tag,
    .cpu_model = .native,
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{ .default_target = default_target });

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = if (target.os_tag) |os| ret: {
        if (os == .windows) {
            const exe = b.addExecutable("smol-pong-zig", "src/nt-gdi/main.zig");
            const libc_path = b.option([]const u8, "libc-path", "Path to C compiler headers, needed for resolving <windows.h>");
            if (mode != .Debug)
                exe.subsystem = .Windows;
            if (libc_path) |path| {
                exe.addIncludePath(path);
            } else @panic("-Dlibc-path option is required");

            exe.code_model = .small;

            exe.linkSystemLibraryName("kernel32");
            exe.linkSystemLibraryName("user32");
            exe.linkSystemLibraryName("gdi32");
            exe.linkSystemLibraryName("ntdll");
            break :ret exe;
        } else @panic("OS unimplemented");
    } else @panic("OS unspecified");

    exe.addPackagePath("backend", "src/backend.zig");
    exe.addPackagePath("game", "src/game.zig");

    if (mode != .Debug)
        exe.omit_frame_pointer = true;
        exe.strip = true;

    exe.want_lto = true;
    exe.single_threaded = true;

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
}
