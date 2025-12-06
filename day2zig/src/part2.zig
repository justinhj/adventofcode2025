const std = @import("std");
const tokenizeAny = std.mem.tokenizeAny;
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

pub const Range = struct {
    const Self = @This();

    start: usize,
    end: usize,

    pub fn init(start: usize, end: usize) Range {
        return .{ .start = start, .end = end };
    }

    pub fn parse(input: []const u8) ZigError!Self {
        var parsed = tokenizeScalar(u8, input, '-');
        const start: usize = std.fmt.parseInt(usize, parsed.next().?, 10) catch return ZigError.ParseFailed;
        const end: usize = std.fmt.parseInt(usize, parsed.next().?, 10) catch return ZigError.ParseFailed;
        const r = init(start, end);
        return r;
    }
};

fn has_repeating_seq(input: u64) ZigError!bool {
    var buffer: [32]u8 = undefined;
    const input_string = std.fmt.bufPrint(&buffer, "{d}", .{input}) catch return ZigError.OutOfBounds;

    for (1..input_string.len / 2 + 1) |len| {
        if (input_string.len % len == 0) {
            const pattern = input_string[0..len];
            var match = true;
            var i: usize = len;
            while (i < input_string.len) : (i += len) {
                if (!std.mem.eql(u8, input_string[i .. i + len], pattern)) {
                    match = false;
                    break;
                }
            }
            if (match) return true;
        }
    }
    return false;
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
    var it = tokenizeAny(u8, file_contents, ",\n");
    var sum: u64 = 0;
    while (it.next()) |next| {
        const r = try Range.parse(next);
        for (r.start .. r.end + 1) |n| {
            if (try has_repeating_seq(n)) {
                sum += n;
            }
        }
    }
    std.debug.print("Sum part 2 {d}.\n", .{sum});
}
