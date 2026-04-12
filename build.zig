const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const grabbing_mod = b.createModule(.{
        .root_source_file = b.path("src/gui-grabbing.zig"),
        .target = target,
        .optimize = optimize,
    });

    const backend_mod = b.createModule(.{
        .root_source_file = b.path("src/backend.zig"),
        .target = target,
        .optimize = optimize,
    });

    const rect_mod = b.createModule(.{
        .root_source_file = b.path("src/Rect.zig"),
        .target = target,
        .optimize = optimize,
    });

    const utils_mod = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    const rl_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const rl_mod = rl_dep.module("raylib");
    const rl_artifact = rl_dep.artifact("raylib");

    exe_mod.addImport("qw_gui", lib_mod);
    exe_mod.addImport("raylib", rl_mod);
    lib_mod.addImport("grabbing", grabbing_mod);
    lib_mod.addImport("backend", backend_mod);
    lib_mod.addImport("Rect", rect_mod);
    lib_mod.addImport("utils", utils_mod);
    backend_mod.addImport("raylib", rl_mod);
    grabbing_mod.addImport("raylib", rl_mod);
    rect_mod.addImport("raylib", rl_mod);
    rect_mod.addImport("backend", backend_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "qw_gui",
        .root_module = lib_mod,
    });

    lib.linkLibrary(rl_artifact);

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "qw_gui",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const backend_unit_tests = b.addTest(.{
        .root_module = backend_mod,
    });

    const run_backend_unit_tests = b.addRunArtifact(backend_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_backend_unit_tests.step);

    for (examples) |e| {
        const example_mod = b.createModule(.{
            .root_source_file = b.path(e.path),
            .target = target,
            .optimize = optimize,
        });

        example_mod.addImport("raylib", rl_mod);
        example_mod.addImport("qw_gui", lib_mod);

        const example_exe = b.addExecutable(.{
            .name = e.name,
            .root_module = example_mod,
        });

        const example_run_cmd = b.addRunArtifact(example_exe);
        const example_run_step = b.step(e.name, e.description);
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

const Example = struct {
    name: []const u8,
    path: []const u8,
    description: []const u8,
};

const examples = [_]Example{
    .{
        .name = "buttons",
        .path = "examples/buttons.zig",
        .description = "Basic showcase of buttons",
    },
};
