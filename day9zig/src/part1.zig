const std = @import("std");
const aoc_utils = @import("aoc_utils");

const Point = struct {
    x: i64,
    y: i64,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    var points = std.ArrayList(Point).initCapacity(allocator, 100) catch return;
    defer points.deinit(allocator);

    var lines = std.mem.tokenizeAny(u8, file_contents, "\n\r");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = std.mem.splitScalar(u8, line, ',');
        const x_str = parts.next() orelse continue;
        const y_str = parts.next() orelse continue;

        const x = try std.fmt.parseInt(i64, std.mem.trim(u8, x_str, " "), 10);
        const y = try std.fmt.parseInt(i64, std.mem.trim(u8, y_str, " "), 10);

        try points.append(allocator, .{ .x = x, .y = y });
    }

    var max_area: u64 = 0;
    const items = points.items;
    for (items, 0..) |p1, i| {
        for (items[i + 1 ..]) |p2| {
            const width = @abs(p1.x - p2.x) + 1;
            const height = @abs(p1.y - p2.y) + 1;
            const area = width * height;
            if (area > max_area) {
                max_area = area;
            }
        }
    }

    std.debug.print("Max area: {d}\n", .{max_area});
}