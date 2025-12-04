const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "part1",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/part1.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run-part1", "Run part1");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe2 = b.addExecutable(.{
        .name = "part2",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/part2.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe2);

    const run_cmd2 = b.addRunArtifact(exe2);
    run_cmd2.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd2.addArgs(args);
    }

    const run_step2 = b.step("run-part2", "Run part2");
    run_step2.dependOn(&run_cmd2.step);
}
