const std = @import("std");

pub fn build(b: *std.Build) void {
    const build_exe = b.option(bool, "build-example", "Build the zig-prompter example") orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const mibu_dep = b.dependency("mibu", .{
        .target = target,
        .optimize = optimize,
    });

    // Create the prompter module
    const zig_prompter_module = b.addModule("prompter", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "mibu", .module = mibu_dep.module("mibu") },
        },
    });

    if (build_exe) {
        const exe = b.addExecutable(.{
            .name = "prompter-example",
            .root_module = b.createModule(.{
                .root_source_file = b.path("example/main.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "prompter", .module = zig_prompter_module },
                },
            }),
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the example!");
        run_step.dependOn(&run_cmd.step);
    }

    const lib_test = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mibu", .module = mibu_dep.module("mibu") },
            },
        }),
    });

    const run_lib_tests = b.addRunArtifact(lib_test);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lib_tests.step);

    const docs_step = b.step("docs", "Generate docs.");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib_test.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);
}
