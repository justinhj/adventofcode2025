const std = @import("std");
const tokenizeScalar = std.mem.tokenizeScalar;
const aoc_utils = @import("aoc_utils");
const AocError = aoc_utils.AocError;

const Day8Error = error {
    ParseError,
} || AocError;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch return Day8Error.FileNotFound;

    std.debug.print("Day 8 Part 1 - File size: {d} bytes\n", .{file_contents.len});

    var rows = std.ArrayList([]u64).initCapacity(allocator, 100) catch return Day8Error.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        var it2 = tokenizeScalar(u8, next, ',');
        var row = allocator.alloc(u64, 3) catch return Day8Error.OutOfMemory;
        while (it2.next()) |next2| {
            for (0..3) |i| {
                row[i] = std.fmt.parseUnsigned(u64, next2, 10) catch return Day8Error.ParseError;
            }
        }
        rows.append(allocator, row) catch return Day8Error.ParseError;
    }

    std.debug.print("row count {d}.\n", .{ rows.items.len });
}
