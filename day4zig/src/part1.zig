const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeScalar = std.mem.tokenizeScalar;

// Custom errors for this day's problem
const DayError = error{
    OutOfBounds,
    NotPaper,
};

// Merge with common errors
const AllErrors = aoc_utils.AocError || DayError;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    // Read into a 2 dimensional array
    var rows = std.ArrayList([]u8).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        const next_copy = try allocator.dupe(u8, next);
        _ = rows.append(allocator, next_copy) catch return aoc_utils.AocError.OutOfMemory;
    }
    draw_map(rows);
    const paper_count = try count_paper(rows);
    std.debug.print("Result {d}.\n", .{paper_count});
}

const Map = std.ArrayList([]u8);

fn count_paper(map: Map) AllErrors!usize {
    var total_count: usize = 0;

    for (map.items, 0..) |row_chars, r_idx| {
        for (row_chars, 0..) |char_at_col, c_idx| {
            if (char_at_col == '@') {
                const count = try count_neighbour_paper(map, @as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)));
                if (count < 4) {
                    total_count += 1;
                }
            }
        }
    }
    return total_count;
}

fn draw_map(rows: Map) void {
    for (rows.items) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

fn count_neighbour_paper(map: Map, row: i32, col: i32) AllErrors!usize {
    // Check if row or col are negative before casting to usize
    if (row < 0 or col < 0) {
        return DayError.OutOfBounds;
    }
    // Now safe to cast to usize for comparison with map dimensions
    const u_row = @as(usize, @intCast(row));
    const u_col = @as(usize, @intCast(col));

    if (u_row >= map.items.len or u_col >= map.items[u_row].len) {
        return DayError.OutOfBounds;
    }

    if (map.items[u_row][u_col] != '@') return DayError.NotPaper;

    var count: usize = 0;
    const directions = [_]i32{ -1, 0, 1 };

    for (directions) |dr| {
        for (directions) |dc| {
            if (dr == 0 and dc == 0) continue;

            const r_i32 = @as(i32, @intCast(row)) + dr;
            const c_i32 = @as(i32, @intCast(col)) + dc;

            if (r_i32 < 0 or r_i32 >= map.items.len) continue;
            const r = @as(usize, @intCast(r_i32));

            if (c_i32 < 0 or c_i32 >= map.items[r].len) continue;
            const c = @as(usize, @intCast(c_i32));

            if (map.items[r][c] == '@') {
                count += 1;
            }
        }
    }
    return count;
}
