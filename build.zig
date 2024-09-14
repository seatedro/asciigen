const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};
pub fn build(b: *std.Build) !void {
    // add a build option that checks if the user wants to build for all targets
    const ci = b.option(bool, "ci", "Build for all targets") orelse false;
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const dep_stb = b.dependency("stb", .{});
    if (ci) {
        for (targets) |target| {
            try buildCi(b, target, optimize, dep_stb);
        }
    } else {
        const target = b.standardTargetOptionsQueryOnly(.{});
        try runZig(b, target, optimize, dep_stb);
    }
}

fn setupExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
    dep_stb: *std.Build.Dependency,
    link_libc: bool,
) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .link_libc = link_libc,
    });

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    linkFfmpeg(exe);

    exe.addCSourceFile(.{ .file = b.path("external/stb.c") });
    exe.addIncludePath(dep_stb.path(""));

    return exe;
}

fn linkFfmpeg(exe: *std.Build.Step.Compile) void {
    exe.linkSystemLibrary2("libavformat", .{ .use_pkg_config = .force });
    exe.linkSystemLibrary2("libavcodec", .{ .use_pkg_config = .force });
    exe.linkSystemLibrary2("libavutil", .{ .use_pkg_config = .force });
    exe.linkSystemLibrary2("libswscale", .{ .use_pkg_config = .force });
    exe.linkSystemLibrary2("libswresample", .{ .use_pkg_config = .force });
}

fn buildCi(
    b: *std.Build,
    target: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
    dep_stb: *std.Build.Dependency,
) !void {
    const exe = try setupExecutable(b, "asciigen", target, optimize, dep_stb, true);

    const target_output = b.addInstallArtifact(exe, .{
        .dest_dir = .{
            .override = .{
                .custom = try target.zigTriple(b.allocator),
            },
        },
    });

    b.getInstallStep().dependOn(&target_output.step);
}

fn runZig(
    b: *std.Build,
    target: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
    dep_stb: *std.Build.Dependency,
) !void {
    const exe = try setupExecutable(
        b,
        "asciigen",
        target,
        optimize,
        dep_stb,
        true,
    );

    const exe_check = try setupExecutable(
        b,
        "asciigen-check",
        target,
        optimize,
        dep_stb,
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
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .link_libc = true,
    });
    linkFfmpeg(unit_tests);
    unit_tests.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    unit_tests.addIncludePath(dep_stb.path(""));
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
