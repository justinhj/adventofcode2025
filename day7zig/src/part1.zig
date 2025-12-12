const std = @import("std");
const aoc_utils = @import("aoc_utils");

fn printTree(grid: std.ArrayList([]u8)) void {
    for (grid.items) |row| {
        std.debug.print("{s}\n", .{row});
    }
    std.debug.print("\n", .{});
}

const Update = struct {
    r: usize,
    c: usize,
    char: u8,
};

fn updateTree(allocator: std.mem.Allocator, grid: std.ArrayList([]u8), split_count: *u32) !bool {
    var updates = std.ArrayList(Update).initCapacity(allocator, 16) catch return false;
    defer updates.deinit(allocator);

    const rows = grid.items.len;
    if (rows == 0) return false;
    const cols = grid.items[0].len;

    for (0..rows - 1) |y| {
        for (0..cols) |x| {
            const current = grid.items[y][x];
            
            if (current == 'S') {
                if (grid.items[y + 1][x] == '.') {
                    try updates.append(allocator, .{ .r = y + 1, .c = x, .char = '|' });
                }
            } else if (current == '|') {
                const below = grid.items[y + 1][x];
                if (below == '.') {
                    try updates.append(allocator, .{ .r = y + 1, .c = x, .char = '|' });
                } else if (below == '^') {
                    var did_split = false;
                    // Check left
                    if (x > 0) {
                        if (grid.items[y + 1][x - 1] == '.') {
                            try updates.append(allocator, .{ .r = y + 1, .c = x - 1, .char = '|' });
                            did_split = true;
                        }
                    }
                    // Check right
                    if (x < cols - 1) {
                        if (grid.items[y + 1][x + 1] == '.') {
                            try updates.append(allocator, .{ .r = y + 1, .c = x + 1, .char = '|' });
                            did_split = true;
                        }
                    }
                    if (did_split) {
                        split_count.* += 1;
                    }
                }
            }
        }
    }

    if (updates.items.len == 0) return false;

    for (updates.items) |u| {
        grid.items[u.r][u.c] = u.char;
    }

    return true;
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

    var split_count: u32 = 0;
    while (try updateTree(allocator, grid, &split_count)) {
        printTree(grid);
    }

    std.debug.print("Split count: {d}\n", .{split_count});
}
