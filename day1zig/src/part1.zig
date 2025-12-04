const std = @import("std");
const day1zig = @import("day1zig");
const tokenizeScalar = std.mem.tokenizeScalar;

const ZigError = error{
    NoFileSupplied,
    FileNotFound,
    IntParseFailed,
    OutOfMemory,
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
    var dial : isize = 50;
    var zero_count : isize = 0;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        const direction : isize = if (next[0] == 'L') -1 else 1;
        const magnitude : isize = std.fmt.parseInt(isize, next[1..], 10) catch return ZigError.IntParseFailed;
        dial = @mod(dial + (direction * magnitude), 100);
        if (dial == 0) {
            zero_count += 1;
        }
        // std.debug.print("Direction {d} Magnitude {d} dial {d}\n", .{ direction, magnitude, dial });
    }
    std.debug.print("zero count {d}\n", .{ zero_count });
}
