const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeScalar = std.mem.tokenizeScalar;

// Custom errors for this day's problem
const DayError = error{
    IntParseFailed,
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

    var dial: isize = 50;
    var zero_count: isize = 0;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        const direction: isize = if (next[0] == 'L') -1 else 1;
        var magnitude: isize = std.fmt.parseInt(isize, next[1..], 10) catch return DayError.IntParseFailed;

        const rotations = @divFloor(magnitude, 100);
        zero_count += rotations;

        magnitude = @mod(magnitude, 100);
        if (magnitude == 0) continue;

        const old_dial = dial;
        dial = @mod(dial + (direction * magnitude), 100);

        if (dial == 0) {
            zero_count += 1;
        } else if (old_dial != 0 and ((direction == 1 and old_dial > dial) or
            (direction == -1 and old_dial < dial)))
        {
            zero_count += 1;
        }
    }

    std.debug.print("Total Password: {d}\n", .{zero_count});
}
