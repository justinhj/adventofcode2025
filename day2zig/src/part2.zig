const std = @import("std");
const aoc_utils = @import("aoc_utils");
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeScalar = std.mem.tokenizeScalar;

// Custom errors for this day's problem
const DayError = error{
    ParseFailed,
    OutOfBounds,
};

// Merge with common errors
const AllErrors = aoc_utils.AocError || DayError;

pub const Range = struct {
    const Self = @This();

    start: usize,
    end: usize,

    pub fn init(start: usize, end: usize) Range {
        return .{ .start = start, .end = end };
    }

    pub fn parse(input: []const u8) AllErrors!Self {
        var parsed = tokenizeScalar(u8, input, '-');
        const start: usize = std.fmt.parseInt(usize, parsed.next().?, 10) catch return DayError.ParseFailed;
        const end: usize = std.fmt.parseInt(usize, parsed.next().?, 10) catch return DayError.ParseFailed;
        const r = init(start, end);
        return r;
    }
};

fn has_repeating_seq(input: u64) AllErrors!bool {
    var buffer: [32]u8 = undefined;
    const input_string = std.fmt.bufPrint(&buffer, "{d}", .{input}) catch return DayError.OutOfBounds;

    outer: for (1..input_string.len / 2 + 1) |len| {
        if (input_string.len % len == 0) {
            const pattern = input_string[0..len];
            var i: usize = len;
            while (i < input_string.len) : (i += len) {
                if (!std.mem.eql(u8, input_string[i .. i + len], pattern)) {
                    continue :outer;
                }
            }
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    var it = tokenizeAny(u8, file_contents, ",\n");
    var sum: u64 = 0;
    while (it.next()) |next| {
        const r = try Range.parse(next);
        for (r.start..r.end + 1) |n| {
            if (try has_repeating_seq(n)) {
                sum += n;
            }
        }
    }
    std.debug.print("Sum part 2 {d}.\n", .{sum});
}
