const std = @import("std");
const aoc_utils = @import("aoc_utils");

const Graph = std.StringHashMap([][]const u8);

const MemoKey = struct {
    node_ptr: usize,
    visited_dac: bool,
    visited_fft: bool,
};

const MemoMap = std.AutoHashMap(MemoKey, u64);

fn countPaths(
    graph: *Graph,
    current: []const u8,
    visited_dac: bool,
    visited_fft: bool,
    memo: *MemoMap,
) u64 {
    // Check if we've reached "out"
    if (std.mem.eql(u8, current, "out")) {
        return if (visited_dac and visited_fft) 1 else 0;
    }

    // Create memo key using pointer as node identifier
    const key = MemoKey{
        .node_ptr = @intFromPtr(current.ptr),
        .visited_dac = visited_dac,
        .visited_fft = visited_fft,
    };

    // Check memo
    if (memo.get(key)) |cached| {
        return cached;
    }

    // Get outputs for this node
    const outputs = graph.get(current) orelse {
        memo.put(key, 0) catch {};
        return 0;
    };

    var count: u64 = 0;
    for (outputs) |next| {
        const new_dac = visited_dac or std.mem.eql(u8, next, "dac");
        const new_fft = visited_fft or std.mem.eql(u8, next, "fft");
        count += countPaths(graph, next, new_dac, new_fft, memo);
    }

    memo.put(key, count) catch {};
    return count;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    // Parse the graph
    var graph = Graph.init(allocator);

    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeSequence(u8, line, ": ");
        const device = parts.next() orelse continue;
        const outputs_str = parts.next() orelse continue;

        // Count outputs first
        var count: usize = 0;
        var counter = std.mem.tokenizeScalar(u8, outputs_str, ' ');
        while (counter.next()) |_| count += 1;

        // Allocate slice and fill
        const outputs = allocator.alloc([]const u8, count) catch continue;
        var output_iter = std.mem.tokenizeScalar(u8, outputs_str, ' ');
        var i: usize = 0;
        while (output_iter.next()) |output| : (i += 1) {
            outputs[i] = output;
        }

        graph.put(device, outputs) catch continue;
    }

    // Memoization map
    var memo = MemoMap.init(allocator);

    const result = countPaths(&graph, "svr", false, false, &memo);

    std.debug.print("{d}\n", .{result});
}
