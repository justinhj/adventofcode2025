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

const MaxAndStart = struct {
    max: u64,
    start: usize,
};

fn max_voltage(input: []const u8, start: usize, limit: usize) MaxAndStart {
    var max: u64 = 0;
    var max_pos: usize = undefined;
    for (start..limit) |i| {
        if (input[i] - '0' > max) {
            max = input[i] - '0';
            max_pos = i;
        }
    }
    return .{ .max = max, .start = max_pos + 1 }; 
}

fn max_voltage_n(input: []const u8, n: usize) u64 {
    var limit: usize = n; 
    var multiplier = std.math.pow(u64, 10, n - 1);
    var sum: u64 = 0;
    var start: usize = 0;

    while (limit > 0) : (limit -= 1) {
        const result = max_voltage(input, start, input.len - n);
        start = result.start;
        sum += result.max * multiplier;
        multiplier /= 10;
    }
    return sum;
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
    var sum: u64 = 0;
    while (it.next()) |next| {
        const mv = max_voltage(next);
        sum += @intCast(mv);
    }
    std.debug.print("Result {d}.\n", .{sum});
}

test "max_voltage test cases" {
    const expected1: MaxAndStart = .{ .max = 9, .start = 1 };
    try std.testing.expectEqual(expected1, max_voltage("987654321111111", 0, 13));
    const expected2: MaxAndStart = .{ .max = 8, .start = 2 };
    try std.testing.expectEqual(expected2, max_voltage("987654321111111", 1, 13));

    try std.testing.expectEqual(98, max_voltage_n("987654321111111", 2));
    try std.testing.expectEqual(89, max_voltage_n("811111111111119", 2));
    // try std.testing.expectEqual(@as(u8, 78), max_voltage("234234234234278"));
    // try std.testing.expectEqual(@as(u8, 92), max_voltage("818181911112111"));
}
