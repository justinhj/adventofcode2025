const std = @import("std");
const aoc_utils = @import("aoc_utils");

fn printTree(grid: std.ArrayList([]u8)) void {
    for (grid.items) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    var grid = std.ArrayList([]u8).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    defer {
        for (grid.items) |row| {
            allocator.free(row);
        }
        grid.deinit(allocator);
    }

    var line_it = std.mem.splitScalar(u8, file_contents, '\n');
    while (line_it.next()) |line| {
        const trimmed = std.mem.trimRight(u8, line, "\r");
        if (trimmed.len == 0) continue;
        
        // Create a mutable copy of the row
        const row = try allocator.dupe(u8, trimmed);
        try grid.append(allocator, row);
    }

    printTree(grid);
}
