const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const tracy = b.dependency("tracy", .{});
    const path = tracy.builder.build_root;
    const tracy_path = try path.join(b.allocator, &[_][]const u8{"/public/tracy"});
    const tracy_c = try path.join(b.allocator, &[_][]const u8{"/public/tracy/TracyC.h"});
    const tracy_client = try path.join(b.allocator, &[_][]const u8{"/public/TracyClient.cpp"});

    const tracy_c_flags: []const []const u8 = if (target.result.os.tag == .windows and target.result.abi == .gnu)
        &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined", "-D_WIN32_WINNT=0x601" }
    else
        &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" };

    const lib = b.addStaticLibrary(.{
        .name = "trazig",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "trazig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibCpp();

    exe.installHeader(tracy_c, "TracyC.h");

    if (target.result.os.tag == .windows) {
        exe.linkSystemLibrary("dbghelp");
        exe.linkSystemLibrary("ws2_32");
    }

    exe.addCSourceFile(.{
        .file = .{
            .path = tracy_client,
        },
        .flags = tracy_c_flags,
    });

    exe.addIncludePath(.{ .path = path.path.? });
    exe.addIncludePath(.{ .path = tracy_path });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
