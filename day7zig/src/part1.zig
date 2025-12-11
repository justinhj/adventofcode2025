const std = @import("std");
const aoc_utils = @import("aoc_utils");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    std.debug.print("Day 7 Part 1 - File size: {d} bytes\n", .{file_contents.len});
    std.debug.print("TODO: Implement solution\n", .{});
}
