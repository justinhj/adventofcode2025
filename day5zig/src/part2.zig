const std = @import("std");
const aoc_utils = @import("aoc_utils");
const DoublyLinkedList = std.DoublyLinkedList;
const tokenizeScalar = std.mem.tokenizeScalar;

// Custom errors for this day's problem
const DayError = error{
    ParseFailed,
    OutOfBounds,
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

    var ranges = std.ArrayList(Range).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    // Split the two sections of input
    var it = std.mem.tokenizeSequence(u8, file_contents, "\n\n");
    if (it.next()) |next| {
        // Parse to an array of ranges
        var it2 = std.mem.tokenizeScalar(u8, next, '\n');
        while (it2.next()) |next2| {
            var it3 = std.mem.tokenizeScalar(u8, next2, '-');
            const start = std.fmt.parseUnsigned(u64, it3.next().?, 10) catch return DayError.ParseFailed;
            const end = std.fmt.parseUnsigned(u64, it3.next().?, 10) catch return DayError.ParseFailed;
            const range = Range{ .fresh = true, .start = start, .end = end };
            try ranges.append(allocator, range);
        }
    }

    std.debug.print("Loaded {d} ranges.\n", .{ranges.items.len});

    // Sort ranges by start
    std.mem.sort(Range, ranges.items, {}, struct {
        fn lessThan(_: void, a: Range, b: Range) bool {
            return a.start < b.start;
        }
    }.lessThan);

    var ranges_dl: std.DoublyLinkedList = .{};

    // Create a doubly linked list of fresh/not-fresh ranges
    for (ranges.items) |*range| {
        insertFreshRange(&ranges_dl, range, allocator) catch return aoc_utils.AocError.OutOfMemory;
    }

    // Debug: print the resulting list
    printRangeList(&ranges_dl);

    // Count total fresh IDs across all fresh ranges
    const fresh_count = countFreshIds(&ranges_dl);
    std.debug.print("Total fresh IDs: {d}.\n", .{fresh_count});
}

const Range = struct {
    fresh: bool,
    start: u64,
    end: u64,
    node: DoublyLinkedList.Node = .{},
};

const RangeList = std.DoublyLinkedList;

fn nodeToRange(node: *RangeList.Node) *Range {
    return @fieldParentPtr("node", node);
}

fn printRangeList(list: *RangeList) void {
    var it = list.first;
    var first = true;
    while (it) |node| : (it = node.next) {
        const range = nodeToRange(node);
        if (!first) {
            std.debug.print(" -> ", .{});
        }
        first = false;
        const fresh_str = if (range.fresh) "fresh" else "not fresh";
        std.debug.print("{s} {d} to {d}", .{ fresh_str, range.start, range.end });
    }
    std.debug.print("\n", .{});
}

fn countFreshIds(list: *RangeList) u64 {
    var total: u64 = 0;
    var it = list.first;
    while (it) |node| : (it = node.next) {
        const range = nodeToRange(node);
        if (range.fresh) {
            total += range.end - range.start + 1;
        }
    }
    return total;
}

// Assumption is that rangelist is pre-sorted by start
fn insertFreshRange(list: *RangeList, new_range: *Range, allocator: std.mem.Allocator) !void {
    if (list.last == null) {
        list.append(&new_range.node);
        return;
    }

    const last_node = list.last.?;
    const last_range = nodeToRange(last_node);

    // Check if we should merge with the last fresh range
    if (last_range.fresh) {
        // Overlapping or adjacent: new_range.start <= last_range.end + 1
        if (new_range.start <= last_range.end + 1) {
            // Merge: extend the last range
            last_range.end = @max(last_range.end, new_range.end);
            return;
        }
        // Gap exists - add not-fresh range then the new fresh range
        const gap = try allocator.create(Range);
        gap.* = Range{ .fresh = false, .start = last_range.end + 1, .end = new_range.start - 1 };
        list.append(&gap.node);
        list.append(&new_range.node);
    } else {
        // Last range is not-fresh, check the fresh range before it
        if (last_node.prev) |prev_node| {
            const prev_range = nodeToRange(prev_node);
            // prev_range must be fresh (alternating pattern)
            if (new_range.start <= prev_range.end + 1) {
                // Merge with previous fresh range, remove the not-fresh gap
                prev_range.end = @max(prev_range.end, new_range.end);
                list.remove(last_node);
                return;
            }
        }
        // Update the not-fresh gap to end just before new_range
        last_range.end = new_range.start - 1;
        list.append(&new_range.node);
    }
}
