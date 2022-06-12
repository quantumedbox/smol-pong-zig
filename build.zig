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

    const exe = switch (target.os_tag orelse @panic("OS unspecified")) {
        .windows => b.addExecutable("smol-pong-zig", "src/NT-GDI/main.zig"),
        else => @panic("Unimplemented target"),
    };

    exe.addPackagePath("backend", "src/backend.zig");
    exe.addPackagePath("game", "src/game.zig");

    switch (target.os_tag orelse @panic("OS unspecified")) {
        .windows => {
            const libc_path = b.option([]const u8, "libc-path", "Path to C compiler headers, needed for resolving <windows.h>");
            if (libc_path) |path|
                exe.addIncludeDir(path);
            exe.subsystem = .Windows;
            exe.link_eh_frame_hdr = false;
            exe.link_emit_relocs = false;
            exe.link_z_notext = true;
            exe.red_zone = false;
            exe.omit_frame_pointer = true;
            exe.pie = false;
            exe.linkSystemLibrary("gdi32");
        },
        else => {},
    }

    exe.want_lto = true;
    exe.single_threaded = true;
    exe.strip = true;

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
