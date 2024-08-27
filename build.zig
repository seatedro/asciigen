const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const dep_stb = b.dependency("stb", .{});

    try runZig(b, dep_stb, target, optimize);
}

fn runZig(
    b: *std.Build,
    dep_stb: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) !void {
    const exe = b.addExecutable(.{
        .name = "asciigen",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe_check = b.addExecutable(.{
        .name = "asciigen-check",
        .root_source_file = b.path("src/check.zig"),
        .target = target,
        .optimize = optimize,
    });
    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));
    exe_check.root_module.addImport("clap", clap.module("clap"));

    exe.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    exe_check.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    exe.addIncludePath(dep_stb.path(""));
    exe_check.addIncludePath(dep_stb.path(""));

    b.installArtifact(exe);

    const check_step = b.step("check", "Run the check");
    check_step.dependOn(&exe_check.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run the test");
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    unit_tests.addIncludePath(dep_stb.path(""));
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
