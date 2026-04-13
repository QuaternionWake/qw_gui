const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var module_array: std.EnumArray(ModuleName, *std.Build.Module) = .init(undefined);
    for (modules) |module| {
        const mod = b.createModule(.{
            .root_source_file = b.path(module.path),
            .target = target,
            .optimize = optimize,
        });
        module_array.set(module.name, mod);
    }

    const rl_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    module_array.set(.raylib, rl_dep.module("raylib"));
    const rl_artifact = rl_dep.artifact("raylib");

    for (modules) |module| {
        const mod = module_array.get(module.name);
        for (module.imports) |import| {
            const imported_mod = module_array.get(import.module_name);
            mod.addImport(import.import_name, imported_mod);
        }
    }

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "qw_gui",
        .root_module = module_array.get(.lib),
    });

    lib.linkLibrary(rl_artifact);

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "qw_gui",
        .root_module = module_array.get(.exe),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    for (unit_tests) |unit_test| {
        const mod = module_array.get(unit_test.module_name);
        const test_compile = b.addTest(.{ .root_module = mod });
        const test_run = b.addRunArtifact(test_compile);
        test_step.dependOn(&test_run.step);
    }

    for (examples) |e| {
        const example_mod = b.createModule(.{
            .root_source_file = b.path(e.path),
            .target = target,
            .optimize = optimize,
        });

        example_mod.addImport("raylib", module_array.get(.raylib));
        example_mod.addImport("qw_gui", module_array.get(.lib));

        const example_exe = b.addExecutable(.{
            .name = e.name,
            .root_module = example_mod,
        });

        const example_run_cmd = b.addRunArtifact(example_exe);
        const example_run_step = b.step(e.name, e.description);
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

const ModuleName = enum {
    exe,
    lib,
    grabbing,
    backend,
    rect,
    utils,
    raylib,
};

const Module = struct {
    name: ModuleName,
    path: []const u8,
    imports: []const Import = &.{},
};

const Import = struct {
    import_name: []const u8,
    module_name: ModuleName,
};

const modules = [_]Module{
    .{
        .name = .exe,
        .path = "src/main.zig",
        .imports = &.{
            .{ .import_name = "qw_gui", .module_name = .lib },
            .{ .import_name = "raylib", .module_name = .raylib },
        },
    },
    .{
        .name = .lib,
        .path = "src/root.zig",
        .imports = &.{
            .{ .import_name = "grabbing", .module_name = .grabbing },
            .{ .import_name = "backend", .module_name = .backend },
            .{ .import_name = "Rect", .module_name = .rect },
            .{ .import_name = "utils", .module_name = .utils },
        },
    },
    .{
        .name = .grabbing,
        .path = "src/gui-grabbing.zig",
        .imports = &.{
            .{ .import_name = "backend", .module_name = .backend },
        },
    },
    .{
        .name = .backend,
        .path = "src/backend.zig",
        .imports = &.{
            .{ .import_name = "raylib", .module_name = .raylib },
        },
    },
    .{
        .name = .rect,
        .path = "src/Rect.zig",
        .imports = &.{
            .{ .import_name = "backend", .module_name = .backend },
        },
    },
    .{
        .name = .utils,
        .path = "src/utils.zig",
    },
};

const UnitTest = struct {
    module_name: ModuleName,
};

const unit_tests = [_]UnitTest{
    .{ .module_name = .lib },
    .{ .module_name = .exe },
    .{ .module_name = .backend },
};

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
