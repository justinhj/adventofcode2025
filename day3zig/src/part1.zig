const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeScalar = std.mem.tokenizeScalar;

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
        for (max_pos + 1..input.len) |i| {
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
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

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
