const std = @import("std");
const aoc_utils = @import("aoc_utils");

const BeamState = struct {
    r: usize,
    c: usize,
};

const Position = struct {
    r: usize,
    c: usize,

    pub fn hash(self: Position) u64 {
        return (@as(u64, self.r) << 32) | @as(u64, self.c);
    }

    pub fn eql(self: Position, other: Position) bool {
        return self.r == other.r and self.c == other.c;
    }
};

fn countPathsFromPosition(
    allocator: std.mem.Allocator,
    grid: []const []const u8,
    start: BeamState,
    memo: *std.AutoHashMap(Position, u64),
) !u64 {
    const rows = grid.len;
    const cols = if (rows > 0) grid[0].len else 0;

    var current = start;

    // Move down until we hit a split or reach the bottom
    while (current.r < rows - 1) {
        const below_r = current.r + 1;
        const below_c = current.c;
        const below = grid[below_r][below_c];

        if (below == '.') {
            // Continue straight down
            current.r = below_r;
        } else if (below == '^') {
            // Check memo first
            const split_pos = Position{ .r = below_r, .c = below_c };
            if (memo.get(split_pos)) |cached| {
                return cached;
            }

            // We hit a splitter! Count paths for both choices
            var path_count: u64 = 0;

            // Try going left
            if (current.c > 0 and grid[below_r][current.c - 1] == '.') {
                const left_count = try countPathsFromPosition(
                    allocator,
                    grid,
                    .{ .r = below_r, .c = current.c - 1 },
                    memo,
                );
                path_count += left_count;
            }

            // Try going right
            if (current.c < cols - 1 and grid[below_r][current.c + 1] == '.') {
                const right_count = try countPathsFromPosition(
                    allocator,
                    grid,
                    .{ .r = below_r, .c = current.c + 1 },
                    memo,
                );
                path_count += right_count;
            }

            // Cache the result
            try memo.put(split_pos, path_count);
            return path_count;
        } else {
            // Hit something else (another beam or obstacle), this path ends
            return 0;
        }
    }

    // Reached the bottom - this is one complete path
    return 1;
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

        const row = try allocator.dupe(u8, trimmed);
        try grid.append(allocator, row);
    }

    // Find starting position (S)
    var start_r: usize = 0;
    var start_c: usize = 0;
    for (grid.items, 0..) |row, r| {
        for (row, 0..) |cell, c| {
            if (cell == 'S') {
                start_r = r;
                start_c = c;
                break;
            }
        }
    }

    // Convert grid to const for passing to recursive function
    var const_grid = std.ArrayList([]const u8).initCapacity(allocator, grid.items.len) catch return;
    defer const_grid.deinit(allocator);
    for (grid.items) |row| {
        try const_grid.append(allocator, row);
    }

    var memo = std.AutoHashMap(Position, u64).init(allocator);
    defer memo.deinit();

    const total_paths = try countPathsFromPosition(
        allocator,
        const_grid.items,
        .{ .r = start_r, .c = start_c },
        &memo,
    );

    std.debug.print("Total number of paths: {d}\n", .{total_paths});
}
