const std = @import("std");

pub const AocError = error{
    NoFileSupplied,
    FileNotFound,
    OutOfMemory,
};

/// Get the input filename from command-line arguments
pub fn getInputFileNameArg(allocator: std.mem.Allocator) AocError![]const u8 {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();
    _ = it.next(); // skip the executable (first arg)
    const filename = it.next() orelse return AocError.NoFileSupplied;
    return filename;
}

/// Load the contents of a file (up to 100KB)
pub fn loadInputFile(allocator: std.mem.Allocator, filename: []const u8) AocError![]const u8 {
    std.debug.print("Processing file {s}.\n", .{filename});

    const open_flags = std.fs.File.OpenFlags{ .mode = .read_only };
    const file = std.fs.cwd().openFile(filename, open_flags) catch {
        return AocError.FileNotFound;
    };
    defer file.close();

    const max_file_size = 100 * 1024; // 100 kb
    const file_contents = file.readToEndAlloc(allocator, max_file_size) catch {
        return AocError.OutOfMemory;
    };

    std.debug.print("Loaded input. {d} bytes.\n", .{file_contents.len});
    return file_contents;
}

/// Combined function: get filename from args and load file contents
pub fn getAndLoadInput(allocator: std.mem.Allocator) AocError![]const u8 {
    const input_file_name = getInputFileNameArg(allocator) catch {
        std.debug.print("Please pass a file path to the input.\n", .{});
        return AocError.NoFileSupplied;
    };
    return loadInputFile(allocator, input_file_name);
}
