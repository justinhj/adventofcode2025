const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a module for common utilities
    const aoc_utils = b.addModule("aoc_utils", .{
        .root_source_file = b.path("common/aoc_utils.zig"),
    });

    // Build executables for all 12 days, both parts
    const days = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
    const parts = [_]u8{ 1, 2 };

    for (days) |day| {
        for (parts) |part| {
            const day_folder = std.fmt.allocPrint(
                b.allocator,
                "day{d}zig",
                .{day},
            ) catch @panic("OOM");

            const src_file = std.fmt.allocPrint(
                b.allocator,
                "{s}/src/part{d}.zig",
                .{ day_folder, part },
            ) catch @panic("OOM");

            const exe_name = std.fmt.allocPrint(
                b.allocator,
                "day{d}-part{d}",
                .{ day, part },
            ) catch @panic("OOM");

            const run_name = std.fmt.allocPrint(
                b.allocator,
                "run-day{d}-part{d}",
                .{ day, part },
            ) catch @panic("OOM");

            // Create executable
            const exe = b.addExecutable(.{
                .name = exe_name,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(src_file),
                    .target = target,
                    .optimize = optimize,
                }),
            });

            // Add the common utilities module
            exe.root_module.addImport("aoc_utils", aoc_utils);

            // Install the executable
            b.installArtifact(exe);

            // Create run step
            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());

            // Allow passing arguments to the executable
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step(run_name, std.fmt.allocPrint(
                b.allocator,
                "Run day {d} part {d}",
                .{ day, part },
            ) catch @panic("OOM"));
            run_step.dependOn(&run_cmd.step);
        }
    }

    // Manual entry for day8 part3 (visualization)
    {
        const exe = b.addExecutable(.{
            .name = "day8-part3",
            .root_module = b.createModule(.{
                .root_source_file = b.path("day8zig/src/part3.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        exe.root_module.addImport("aoc_utils", aoc_utils);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run-day8-part3", "Run day 8 part 3");
        run_step.dependOn(&run_cmd.step);
    }
}
