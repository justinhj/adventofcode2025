const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
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

    var ranges = std.ArrayList(Range).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    // Split the two sections of input
    var it = std.mem.tokenizeSequence(u8, file_contents, "\n\n");
    if (it.next()) |next| {
        // Parse to an array of ranges
        var it2 = std.mem.tokenizeScalar(u8, next, '\n');
        while (it2.next()) |next2| {
            var it3 = std.mem.tokenizeScalar(u8, next2, '-');
            const start = std.fmt.parseUnsigned(u64, it3.next().?, 10) catch return ZigError.ParseFailed;
            const end = std.fmt.parseUnsigned(u64, it3.next().?, 10) catch return ZigError.ParseFailed;
            const range = Range { .fresh = true, .start = start, .end = end };    
            try ranges.append(allocator, range);
        }
    }

    std.debug.print("Loaded {d} ranges.\n", .{ranges.items.len});

    var max: u64 = 0;

    if (it.next()) |next| {
        var it2 = std.mem.tokenizeScalar(u8, next, '\n');
        while (it2.next()) |numstr| {
            const num = std.fmt.parseUnsigned(u64, numstr, 10) catch return ZigError.ParseFailed;
            if (num > max) {
                max = num;
            }
        }
    }

    var ranges_dl: std.DoublyLinkedList = .{};

    // Create a doubly linked list of ranges
    for (ranges.items) |range| {
        ranges_dl.append(&range.node);
    }


    std.debug.print("Max {d}\n", .{ max });
    // Read into a 2 dimensional array
    // var rows = std.ArrayList([]u8).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    // var it = tokenizeScalar(u8, file_contents, '\n');
    // while (it.next()) |next| {
    //     const next_copy = try allocator.dupe(u8, next);
    //     _ = rows.append(allocator, next_copy) catch return ZigError.OutOfMemory;
    // }
    // draw_map(rows);
    // const paper_count = try count_paper(rows);
    // std.debug.print("Result {d}.\n", .{ paper_count });
}

const Range = struct {
    fresh: bool,
    start: u64,
    end: u64,
    node: DoublyLinkedList.Node = .{},
};
