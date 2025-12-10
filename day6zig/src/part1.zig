const std = @import("std");
const tokenizeScalar = std.mem.tokenizeScalar;

const ZigError = error{
    NoFileSupplied,
    FileNotFound,
    ParseFailed,
    OutOfMemory,
    OutOfBounds,
};

fn getInputFileNameArg(allocator: std.mem.Allocator) ZigError![]const u8 {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();
    _ = it.next(); // skip the executable (first arg)
    const filename = it.next() orelse return ZigError.NoFileSupplied;
    return filename;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    // Note the arena allocator is convenient here because we don't free
    // anything until the end, it simplifies the freeing.
    const allocator = arena.allocator();
    const input_file_name = getInputFileNameArg(allocator) catch {
        std.debug.print("Please pass a file path to the input.\n", .{});
        return;
    };
    std.debug.print("Processing file {s}.\n", .{input_file_name});

    const open_flags = std.fs.File.OpenFlags{ .mode = .read_only };
    const file = std.fs.cwd().openFile(input_file_name, open_flags) catch {
        return ZigError.FileNotFound;
    };
    defer file.close();

    const max_file_size = 100 * 1024; // 100 kb
    const file_contents = try file.readToEndAlloc(allocator, max_file_size);
    defer allocator.free(file_contents);

    std.debug.print("Loaded input. {d} bytes.\n", .{file_contents.len});

    var it = tokenizeScalar(u8, file_contents, '\n');
    var rows = std.ArrayList([]const u8).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;

    while (it.next()) |next| {
        rows.append(allocator, next) catch return ZigError.OutOfMemory;
    }

    if (rows.items.len < 2) {
        std.debug.print("Input too short.\n", .{});
        return;
    }

    // Last row is operators
    const ops_line = rows.pop().?;
    var ops = std.ArrayList(u8).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    var ops_it = tokenizeScalar(u8, ops_line, ' ');
    while (ops_it.next()) |op_token| {
        if (op_token.len > 0) {
            ops.append(allocator, op_token[0]) catch return ZigError.OutOfMemory;
        }
    }

    // Remaining rows are numbers
    var grid = std.ArrayList(std.ArrayList(u64)).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    for (rows.items) |row_str| {
        var row_nums = std.ArrayList(u64).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
        var nums_it = tokenizeScalar(u8, row_str, ' ');
        while (nums_it.next()) |num_token| {
            const num = std.fmt.parseUnsigned(u64, num_token, 10) catch return ZigError.OutOfMemory;
            row_nums.append(allocator, num) catch return ZigError.OutOfMemory;
        }
        grid.append(allocator, row_nums) catch return ZigError.OutOfMemory;
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
