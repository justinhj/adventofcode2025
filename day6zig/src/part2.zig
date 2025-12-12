const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeScalar = std.mem.tokenizeScalar;

// Custom errors for this day's problem
const DayError = error{
    ParseFailed,
    OutOfBounds,
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

    // 1. Split into rows
    var rows = try std.ArrayList([]const u8).initCapacity(allocator, 100);
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |row| {
        try rows.append(allocator, row);
    }

    if (rows.items.len < 2) {
        std.debug.print("Input too short.\n", .{});
        return;
    }

    // 2. Determine grid dimensions
    var max_width: usize = 0;
    for (rows.items) |row| {
        if (row.len > max_width) max_width = row.len;
    }

    // 3. Process columns
    var total_sum: u64 = 0;
    var current_block_cols = try std.ArrayList(usize).initCapacity(allocator, 20);

    var col_idx: usize = 0;
    while (col_idx < max_width) : (col_idx += 1) {
        if (isSeparatorColumn(rows.items, col_idx)) {
            if (current_block_cols.items.len > 0) {
                const block_val = try processBlock(allocator, rows.items, current_block_cols.items);
                total_sum += block_val;
                current_block_cols.clearRetainingCapacity();
            }
        } else {
            try current_block_cols.append(allocator, col_idx);
        }
    }
    // Process final block if exists
    if (current_block_cols.items.len > 0) {
        const block_val = try processBlock(allocator, rows.items, current_block_cols.items);
        total_sum += block_val;
    }

    std.debug.print("Solution: {d}\n", .{total_sum});
}

fn getChar(rows: [][]const u8, row: usize, col: usize) u8 {
    if (row >= rows.len) return ' ';
    const r = rows[row];
    if (col >= r.len) return ' ';
    return r[col];
}

fn isSeparatorColumn(rows: [][]const u8, col: usize) bool {
    for (0..rows.len) |r| {
        if (getChar(rows, r, col) != ' ') return false;
    }
    return true;
}

fn processBlock(allocator: std.mem.Allocator, rows: [][]const u8, cols: []const usize) !u64 {
    // Find operator in the last row
    const last_row_idx = rows.len - 1;
    var op: u8 = 0; // 0 means not found yet

    // The operator might be in any of the columns of this block in the last row
    for (cols) |c| {
        const char = getChar(rows, last_row_idx, c);
        if (char == '+' or char == '*') {
            op = char;
            break;
        }
    }

    std.debug.assert(op != 0);
    var result: u64 = if (op == '*') 1 else 0;

    for (cols) |c| {
        var num_str = try std.ArrayList(u8).initCapacity(allocator, 20);
        defer num_str.deinit(allocator);

        // Rows 0 to last_row_idx - 1 are digits
        for (0..last_row_idx) |r| {
            const char = getChar(rows, r, c);
            if (std.ascii.isDigit(char)) {
                try num_str.append(allocator, char);
            }
        }

        if (num_str.items.len > 0) {
            const num = try std.fmt.parseUnsigned(u64, num_str.items, 10);
            if (op == '*') {
                result *= num;
            } else {
                result += num;
            }
        }
    }

    return result;
}
