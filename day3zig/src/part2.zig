const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeScalar = std.mem.tokenizeScalar;

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
        const result = max_voltage(input, start, input.len - (limit - 1));
        start = result.start;
        sum += result.max * multiplier;
        multiplier /= 10;
    }
    return sum;
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
        const mv = max_voltage_n(next, 12);
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
    try std.testing.expectEqual(78, max_voltage_n("234234234234278", 2));
    try std.testing.expectEqual(92, max_voltage_n("818181911112111", 2));

    try std.testing.expectEqual(987654321111, max_voltage_n("987654321111111", 12));
    try std.testing.expectEqual(811111111119, max_voltage_n("811111111111119", 12));
    try std.testing.expectEqual(434234234278, max_voltage_n("234234234234278", 12));
    try std.testing.expectEqual(888911112111, max_voltage_n("818181911112111", 12));
    try std.testing.expectEqual(3121910778619, 987654321111 + 811111111119 + 434234234278 + 888911112111);
}
