const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const target = b.standardTargetOptions(.{});
    const dep_stb = b.dependency("stb", .{});

    const stb_module = b.addModule("stb", .{
        .root_source_file = b.path("external/stb.zig"),
        .target = target,
        .optimize = optimize,
    });
    stb_module.addIncludePath(dep_stb.path(""));
    stb_module.addCSourceFile(.{ .file = b.path("external/stb.c") });
    const av_module = b.addModule("av", .{
        .root_source_file = b.path("external/av.zig"),
        .target = target,
        .optimize = optimize,
    });
    linkFfmpeg(av_module);
    const libglyph = b.addModule("libglyph", .{
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "stb", .module = stb_module },
        },
    });
    const term_module = b.addModule("libglyphterm", .{
        .root_source_file = b.path("src/term.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "libglyph", .module = libglyph },
        },
    });
    const video_module = b.addModule("libglyphav", .{
        .root_source_file = b.path("src/video.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "stb", .module = stb_module },
            .{ .name = "av", .module = av_module },
            .{ .name = "libglyph", .module = libglyph },
            .{ .name = "libglyphterm", .module = term_module },
        },
    });
    const image_module = b.addModule("libglyphimg", .{
        .root_source_file = b.path("src/image.zig"),
        .imports = &.{
            .{ .name = "stb", .module = stb_module },
            .{ .name = "av", .module = av_module },
            .{ .name = "libglyph", .module = libglyph },
            .{ .name = "libglyphterm", .module = term_module },
        },
    });
    try runZig(
        b,
        target,
        optimize,
        libglyph,
        image_module,
        video_module,
        term_module,
    );
}

fn setupExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libglyph: *std.Build.Module,
    image_module: *std.Build.Module,
    video_module: *std.Build.Module,
    term_module: *std.Build.Module,
    link_libc: bool,
) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = link_libc,
    });

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));
    exe.root_module.addImport("libglyph", libglyph);
    exe.root_module.addImport("libglyphimg", image_module);
    exe.root_module.addImport("libglyphav", video_module);
    exe.root_module.addImport("libglyphterm", term_module);

    return exe;
}

fn setupTest(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libglyph: *std.Build.Module,
    image_module: *std.Build.Module,
    video_module: *std.Build.Module,
    term_module: *std.Build.Module,
    link_libc: bool,
) !*std.Build.Step.Compile {
    const unit_test = b.addTest(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = link_libc,
    });

    const clap = b.dependency("clap", .{});
    unit_test.root_module.addImport("clap", clap.module("clap"));
    unit_test.root_module.addImport("libglyph", libglyph);
    unit_test.root_module.addImport("libglyphimg", image_module);
    unit_test.root_module.addImport("libglyphav", video_module);
    unit_test.root_module.addImport("libglyphterm", term_module);

    return unit_test;
}

fn linkFfmpeg(lib: *std.Build.Module) void {
    lib.linkSystemLibrary("libavformat", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary("libavcodec", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary("libavutil", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary("libswscale", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary("libswresample", .{ .use_pkg_config = .force });
}

fn runZig(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libglyph: *std.Build.Module,
    image_module: *std.Build.Module,
    video_module: *std.Build.Module,
    term_module: *std.Build.Module,
) !void {
    const exe = try setupExecutable(
        b,
        "asciigen",
        target,
        optimize,
        libglyph,
        image_module,
        video_module,
        term_module,
        true,
    );

    const exe_check = try setupExecutable(
        b,
        "asciigen-check",
        target,
        optimize,
        libglyph,
        image_module,
        video_module,
        term_module,
        false,
    );
    const check_step = b.step("check", "Run the check");
    check_step.dependOn(&exe_check.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run the test");
    const unit_tests = try setupTest(
        b,
        "asciigen-check",
        target,
        optimize,
        libglyph,
        image_module,
        video_module,
        term_module,
        false,
    );
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
