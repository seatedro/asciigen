const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
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
        try runZig(b, dep_stb, target, optimize);
    }
}

fn buildCi(
    b: *std.Build,
    target: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
    dep_stb: *std.Build.Dependency,
) !void {
    const exe = b.addExecutable(.{
        .name = "asciigen",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .link_libc = true,
    });

    const target_output = b.addInstallArtifact(exe, .{
        .dest_dir = .{
            .override = .{
                .custom = try target.zigTriple(b.allocator),
            },
        },
    });

    b.getInstallStep().dependOn(&target_output.step);

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    exe.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    exe.addIncludePath(dep_stb.path(""));
}

fn runZig(
    b: *std.Build,
    dep_stb: *std.Build.Dependency,
    target: std.Target.Query,
    optimize: std.builtin.OptimizeMode,
) !void {
    const exe = b.addExecutable(.{
        .name = "asciigen",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .link_libc = true,
    });

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));

    exe.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    exe.addIncludePath(dep_stb.path(""));

    const exe_check = b.addExecutable(.{
        .name = "asciigen-check",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
    });
    exe_check.root_module.addImport("clap", clap.module("clap"));
    exe_check.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    exe_check.addIncludePath(dep_stb.path(""));
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
    });
    unit_tests.addCSourceFile(.{ .file = b.path("stb/stb.c") });
    unit_tests.addIncludePath(dep_stb.path(""));
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
