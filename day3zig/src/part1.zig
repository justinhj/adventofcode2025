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

fn max_voltage(input: []const u8) u8 {
    var max: u8 = 0;
    var max_pos: usize = undefined;
    for (0..input.len - 1) |i| {
        if (input[i] - '0' > max) {
            max = input[i] - '0';
            max_pos = i;
        }
    }
    if (max_pos == input.len - 2) {
        return (10 * max) + input[input.len - 1] - '0'; 
    } else {
        var max2: u8 = 0;
        for (max_pos+1..input.len) |i| {
            if (input[i] - '0' > max2) {
                max2 = input[i] - '0';
            }
        }
        return (10 * max) + max2;
    }
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
    try std.testing.expectEqual(@as(u8, 98), max_voltage("987654321111111"));
    try std.testing.expectEqual(@as(u8, 89), max_voltage("811111111111119"));
    try std.testing.expectEqual(@as(u8, 78), max_voltage("234234234234278"));
    try std.testing.expectEqual(@as(u8, 92), max_voltage("818181911112111"));
}
