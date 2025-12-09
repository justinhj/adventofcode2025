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
            const range = Range{ .fresh = true, .start = start, .end = end };
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

    // for reference, operations with doubly linked lists
    // list.append(&two.node); // {2}
    // list.append(&five.node); // {2, 5}
    // list.prepend(&one.node); // {1, 2, 5}
    // list.insertBefore(&five.node, &four.node); // {1, 2, 4, 5}
    // list.insertAfter(&two.node, &three.node); // {1, 2, 3, 4, 5}

    // // Traverse forwards.
    // {
    // var it = list.first;
    // var index: u32 = 1;
    // while (it) |node| : (it = node.next) {
    //     const l: *L = @fieldParentPtr("node", node);
    //     try testing.expect(l.data == index);
    //     index += 1;
    // }
    // }

    // // Traverse backwards.
    // {
    // var it = list.last;
    // var index: u32 = 1;
    // while (it) |node| : (it = node.prev) {
    //     const l: *L = @fieldParentPtr("node", node);
    //     try testing.expect(l.data == (6 - index));
    //     index += 1;
    // }
    // }

    // _ = list.popFirst(); // {2, 3, 4, 5}
    // _ = list.pop(); // {2, 3, 4}
    // list.remove(&three.node); // {2, 4}

    // Create a doubly linked list of fresh/not-fresh ranges
    for (ranges.items) |*range| {
        insertFreshRange(&ranges_dl, range, allocator) catch return ZigError.OutOfMemory;
    }

    // Debug: print the resulting list
    printRangeList(&ranges_dl);

    std.debug.print("Max {d}\n", .{max});
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

fn insertFreshRange(list: *RangeList, new_range: *Range, allocator: std.mem.Allocator) !void {
    // If list is empty, just append the new range
    if (list.first == null) {
        list.append(&new_range.node);
        return;
    }

    // Find where to insert (first range that starts after or overlaps with new_range)
    var it = list.first;
    var insert_before: ?*RangeList.Node = null;
    var merge_start: ?*RangeList.Node = null;
    var merge_end: ?*RangeList.Node = null;

    while (it) |node| : (it = node.next) {
        const range = nodeToRange(node);

        // Check if this range overlaps or is adjacent to new_range
        if (range.fresh) {
            // Overlapping or adjacent: new_range.start <= range.end + 1 AND new_range.end + 1 >= range.start
            if (new_range.start <= range.end + 1 and new_range.end + 1 >= range.start) {
                if (merge_start == null) {
                    merge_start = node;
                }
                merge_end = node;
            }
        }

        // Find insertion point (first range that starts after new_range)
        if (insert_before == null and range.start > new_range.start) {
            insert_before = node;
        }
    }

    // If we found overlapping fresh ranges, merge them
    if (merge_start != null and merge_end != null) {
        const first_range = nodeToRange(merge_start.?);
        const last_range = nodeToRange(merge_end.?);

        // Calculate merged range
        const merged_start = @min(new_range.start, first_range.start);
        const merged_end = @max(new_range.end, last_range.end);

        // Update first_range to be the merged range
        first_range.start = merged_start;
        first_range.end = merged_end;

        // Remove all nodes between merge_start and merge_end (exclusive of merge_start)
        var remove_it = merge_start.?.next;
        while (remove_it) |remove_node| {
            const next = remove_node.next;
            if (remove_node == merge_end.?.next) break;
            list.remove(remove_node);
            remove_it = next;
        }

        // Now fix up the not-fresh gaps
        // Check if we need a not-fresh before the merged range
        if (merge_start.?.prev) |prev_node| {
            const prev_range = nodeToRange(prev_node);
            if (prev_range.fresh) {
                // Need to insert a not-fresh gap
                if (prev_range.end + 1 < merged_start) {
                    const gap = try allocator.create(Range);
                    gap.* = Range{ .fresh = false, .start = prev_range.end + 1, .end = merged_start - 1 };
                    list.insertAfter(prev_node, &gap.node);
                }
            } else {
                // Update the existing not-fresh gap
                prev_range.end = merged_start - 1;
                if (prev_range.start > prev_range.end) {
                    list.remove(prev_node);
                }
            }
        }

        // Check if we need a not-fresh after the merged range
        if (merge_start.?.next) |next_node| {
            const next_range = nodeToRange(next_node);
            if (next_range.fresh) {
                // Need to insert a not-fresh gap
                if (merged_end + 1 < next_range.start) {
                    const gap = try allocator.create(Range);
                    gap.* = Range{ .fresh = false, .start = merged_end + 1, .end = next_range.start - 1 };
                    list.insertAfter(merge_start.?, &gap.node);
                }
            } else {
                // Update the existing not-fresh gap
                next_range.start = merged_end + 1;
                if (next_range.start > next_range.end) {
                    list.remove(next_node);
                }
            }
        }

        return;
    }

    // No merge needed - insert the new range and add not-fresh gaps as needed
    if (insert_before) |before_node| {
        const before_range = nodeToRange(before_node);

        // Insert new_range before this node
        list.insertBefore(before_node, &new_range.node);

        // Add not-fresh gap after new_range if needed
        if (new_range.end + 1 < before_range.start) {
            const gap_after = try allocator.create(Range);
            gap_after.* = Range{ .fresh = false, .start = new_range.end + 1, .end = before_range.start - 1 };
            list.insertAfter(&new_range.node, &gap_after.node);
        }

        // Check if there's a node before new_range and add gap if needed
        if (new_range.node.prev) |prev_node| {
            const prev_range = nodeToRange(prev_node);
            if (prev_range.fresh and prev_range.end + 1 < new_range.start) {
                const gap_before = try allocator.create(Range);
                gap_before.* = Range{ .fresh = false, .start = prev_range.end + 1, .end = new_range.start - 1 };
                list.insertAfter(prev_node, &gap_before.node);
            } else if (!prev_range.fresh) {
                // Update the existing not-fresh gap to end just before new_range
                prev_range.end = new_range.start - 1;
            }
        }
    } else {
        // Append at the end
        const last_node = list.last.?;
        const last_range = nodeToRange(last_node);

        // Add not-fresh gap before if needed
        if (last_range.end + 1 < new_range.start) {
            const gap = try allocator.create(Range);
            gap.* = Range{ .fresh = false, .start = last_range.end + 1, .end = new_range.start - 1 };
            list.append(&gap.node);
        }

        list.append(&new_range.node);
    }
}
