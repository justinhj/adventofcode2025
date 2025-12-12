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

    var it = tokenizeScalar(u8, file_contents, '\n');
    var rows = std.ArrayList([]const u8).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;

    while (it.next()) |next| {
        rows.append(allocator, next) catch return aoc_utils.AocError.OutOfMemory;
    }

    if (rows.items.len < 2) {
        std.debug.print("Input too short.\n", .{});
        return;
    }

    // Last row is operators
    const ops_line = rows.pop().?;
    var ops = std.ArrayList(u8).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    var ops_it = tokenizeScalar(u8, ops_line, ' ');
    while (ops_it.next()) |op_token| {
        if (op_token.len > 0) {
            ops.append(allocator, op_token[0]) catch return aoc_utils.AocError.OutOfMemory;
        }
    }

    // Remaining rows are numbers
    var grid = std.ArrayList(std.ArrayList(u64)).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    for (rows.items) |row_str| {
        var row_nums = std.ArrayList(u64).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
        var nums_it = tokenizeScalar(u8, row_str, ' ');
        while (nums_it.next()) |num_token| {
            const num = std.fmt.parseUnsigned(u64, num_token, 10) catch return aoc_utils.AocError.OutOfMemory;
            row_nums.append(allocator, num) catch return aoc_utils.AocError.OutOfMemory;
        }
        grid.append(allocator, row_nums) catch return aoc_utils.AocError.OutOfMemory;
    }

    // Process column calculations and aggregate
    var total_sum: u64 = 0;
    for (ops.items, 0..) |op, col_idx| {
        var col_val: u64 = if (op == '*') 1 else 0;

        for (grid.items) |row| {
            if (col_idx < row.items.len) {
                const val = row.items[col_idx];
                if (op == '*') {
                    col_val *= val;
                } else if (op == '+') {
                    col_val += val;
                }
            }
        }
        total_sum += col_val;
    }

    std.debug.print("Solution: {d}\n", .{total_sum});
}
