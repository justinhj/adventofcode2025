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

    // Read into a 2 dimensional array
    var rows = std.ArrayList([]u8).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        const next_copy = try allocator.dupe(u8, next);
        _ = rows.append(allocator, next_copy) catch return ZigError.OutOfMemory;
    }
    draw_map(rows);
    std.debug.print("Result .\n", .{});
}

