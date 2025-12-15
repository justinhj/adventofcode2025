const std = @import("std");
const tokenizeScalar = std.mem.tokenizeScalar;
const aoc_utils = @import("aoc_utils");
const AocError = aoc_utils.AocError;
const Order = std.math.Order;
const PriorityQueue = std.PriorityQueue;

const Day8Error = error{
    ParseError,
} || AocError;

const CircuitEntry = struct {
    vector: [3]i64,
    index: u64,
};

const CircuitDistance = struct {
    vec1: [3]i64,
    vec2: [3]i64,
    sqr_distance: u64,
};

// Calculate squared Euclidean distance between two 3D vectors
fn sqrDist(vec1: [3]i64, vec2: [3]i64) u64 {
    var sum: u64 = 0;
    for (0..3) |i| {
        const diff = vec1[i] - vec2[i];
        sum += @intCast(@as(i128, diff) * @as(i128, diff));
    }
    return sum;
}

// Comparison function for priority queue - minimize sqr_distance
fn distLessThan(context: void, a: CircuitDistance, b: CircuitDistance) Order {
    _ = context;
    return std.math.order(a.sqr_distance, b.sqr_distance);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch return Day8Error.FileNotFound;

    std.debug.print("Day 8 Part 1 - File size: {d} bytes\n", .{file_contents.len});

    // Parse into CircuitEntry structs with index = maxInt (unassigned)
    var entries = std.ArrayList(CircuitEntry).initCapacity(allocator, 100) catch return Day8Error.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |line| {
        var it2 = tokenizeScalar(u8, line, ',');
        var vector: [3]i64 = undefined;
        var col: usize = 0;
        while (it2.next()) |num_str| : (col += 1) {
            if (col >= 3) break;
            vector[col] = std.fmt.parseInt(i64, num_str, 10) catch return Day8Error.ParseError;
        }
        if (col == 3) {
            entries.append(allocator, CircuitEntry{
                .vector = vector,
                .index = std.math.maxInt(u64),
            }) catch return Day8Error.OutOfMemory;
        }
    }

    std.debug.print("Parsed {d} entries.\n", .{entries.items.len});

    // Create HashMap for vector -> entry index lookup
    const VectorHashContext = struct {
        pub fn hash(self: @This(), key: [3]i64) u64 {
            _ = self;
            var h: u64 = 0;
            for (key) |v| {
                h = h *% 31 +% @as(u64, @bitCast(v));
            }
            return h;
        }
        pub fn eql(self: @This(), a: [3]i64, b: [3]i64) bool {
            _ = self;
            return a[0] == b[0] and a[1] == b[1] and a[2] == b[2];
        }
    };
    var vector_to_idx = std.HashMap([3]i64, usize, VectorHashContext, 80).init(allocator);

    for (entries.items, 0..) |entry, i| {
        try vector_to_idx.put(entry.vector, i);
    }

    // Create priority queue and populate with all pairs
    var dist_pq = PriorityQueue(CircuitDistance, void, distLessThan).init(allocator, {});

    for (0..entries.items.len) |i| {
        for ((i + 1)..entries.items.len) |j| {
            const vec1 = entries.items[i].vector;
            const vec2 = entries.items[j].vector;
            try dist_pq.add(CircuitDistance{
                .vec1 = vec1,
                .vec2 = vec2,
                .sqr_distance = sqrDist(vec1, vec2),
            });
        }
    }

    std.debug.print("Priority queue has {d} pairs.\n", .{dist_pq.count()});

    // Process priority queue - attempt N/2 connections (where N = number of junction boxes)
    // Pairs already in same circuit still count toward the limit
    var next_circuit_index: u64 = 0;
    var pairs_processed: u64 = 0;
    var actual_merges: u64 = 0;
    const max_pairs: u64 = @intCast(entries.items.len / 2);

    while (dist_pq.removeOrNull()) |dist| {
        if (pairs_processed >= max_pairs) break;
        pairs_processed += 1;

        const idx1 = vector_to_idx.get(dist.vec1).?;
        const idx2 = vector_to_idx.get(dist.vec2).?;

        const circuit1 = entries.items[idx1].index;
        const circuit2 = entries.items[idx2].index;

        const max_idx = std.math.maxInt(u64);

        if (circuit1 < max_idx and circuit2 < max_idx) {
            // Both already assigned
            if (circuit1 == circuit2) {
                // Same circuit - nothing happens (but still counted as a pair)
                continue;
            } else {
                // Different circuits - merge them
                for (entries.items) |*e| {
                    if (e.index == circuit2) {
                        e.index = circuit1;
                    }
                }
                actual_merges += 1;
            }
        } else if (circuit1 < max_idx) {
            // Only first has circuit - assign second to same circuit
            entries.items[idx2].index = circuit1;
            actual_merges += 1;
        } else if (circuit2 < max_idx) {
            // Only second has circuit - assign first to same circuit
            entries.items[idx1].index = circuit2;
            actual_merges += 1;
        } else {
            // Neither has circuit - create new circuit
            entries.items[idx1].index = next_circuit_index;
            entries.items[idx2].index = next_circuit_index;
            next_circuit_index += 1;
            actual_merges += 1;
        }
    }

    std.debug.print("Processed {d} pairs, {d} actual merges.\n", .{ pairs_processed, actual_merges });

    // Assign unique circuit indices to unassigned entries (they form circuits of size 1)
    for (entries.items) |*entry| {
        if (entry.index == std.math.maxInt(u64)) {
            entry.index = next_circuit_index;
            next_circuit_index += 1;
        }
    }

    // Count circuit sizes
    var circuit_counts = std.AutoHashMap(u64, u64).init(allocator);

    for (entries.items) |entry| {
        const result = try circuit_counts.getOrPut(entry.index);
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
    }

    std.debug.print("Found {d} circuits.\n", .{circuit_counts.count()});

    // Find top 3 circuit sizes
    var sizes = std.ArrayList(u64).initCapacity(allocator, 100) catch return Day8Error.OutOfMemory;
    var count_iter = circuit_counts.valueIterator();
    while (count_iter.next()) |count| {
        sizes.append(allocator, count.*) catch return Day8Error.OutOfMemory;
    }

    // Sort descending
    std.mem.sort(u64, sizes.items, {}, std.sort.desc(u64));

    std.debug.print("Circuit sizes (sorted): ", .{});
    for (sizes.items) |s| {
        std.debug.print("{d} ", .{s});
    }
    std.debug.print("\n", .{});

    // Multiply top 3
    var result: u64 = 1;
    const top_n = @min(3, sizes.items.len);
    for (0..top_n) |i| {
        result *= sizes.items[i];
    }

    std.debug.print("Answer: {d}\n", .{result});
}
