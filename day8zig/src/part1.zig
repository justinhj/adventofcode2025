const std = @import("std");
const aoc_utils = @import("aoc_utils");

const Day8Error = error{ ParseError } || std.mem.Allocator.Error;

// 1. Store indices directly, no need for vectors here
const Connection = struct {
    u: usize,
    v: usize,
    dist_sq: u64,

    // Sorting predicate for std.mem.sort
    pub fn lessThan(_: void, a: Connection, b: Connection) bool {
        return a.dist_sq < b.dist_sq;
    }
};

const Point = struct {
    x: i64,
    y: i64,
    z: i64,
};

// 2. Standard Union-Find (Disjoint Set Union) Data Structure
// This effectively manages the "circuits"
const DisjointSet = struct {
    parent: []usize,
    size: []u64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, count: usize) !DisjointSet {
        const parent = try allocator.alloc(usize, count);
        const size = try allocator.alloc(u64, count);
        
        for (0..count) |i| {
            parent[i] = i;
            size[i] = 1;
        }

        return DisjointSet{
            .parent = parent,
            .size = size,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DisjointSet) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.size);
    }

    // Find the representative (root) of the set, with path compression
    pub fn find(self: *DisjointSet, i: usize) usize {
        if (self.parent[i] == i) return i;
        self.parent[i] = self.find(self.parent[i]); // Path compression
        return self.parent[i];
    }

    // Merge two sets. Returns true if they were merged, false if already same set.
    pub fn unionSets(self: *DisjointSet, i: usize, j: usize) bool {
        const root_i = self.find(i);
        const root_j = self.find(j);

        if (root_i != root_j) {
            // Union by size: attach smaller tree to larger tree
            if (self.size[root_i] < self.size[root_j]) {
                self.parent[root_i] = root_j;
                self.size[root_j] += self.size[root_i];
            } else {
                self.parent[root_j] = root_i;
                self.size[root_i] += self.size[root_j];
            }
            return true;
        }
        return false;
    }
};

fn sqrDist(a: Point, b: Point) u64 {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const dz = a.z - b.z;
    // Use @intCast to ensure we don't overflow before casting to u64, 
    // though dist_sq will fit in u64 unless coordinates are massive.
    return @intCast(dx * dx + dy * dy + dz * dz);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // -- Parsing --
    const file_contents = try aoc_utils.getAndLoadInput(allocator);
    var points = std.ArrayList(Point).initCapacity(allocator, 1000) catch return Day8Error.OutOfMemory;
    
    var line_it = std.mem.tokenizeScalar(u8, file_contents, '\n');
    while (line_it.next()) |line| {
        var num_it = std.mem.tokenizeScalar(u8, line, ',');
        const x_str = num_it.next() orelse continue;
        const y_str = num_it.next() orelse continue;
        const z_str = num_it.next() orelse continue;

        points.append(allocator, Point{
            .x = try std.fmt.parseInt(i64, x_str, 10),
            .y = try std.fmt.parseInt(i64, y_str, 10),
            .z = try std.fmt.parseInt(i64, z_str, 10),
        }) catch return Day8Error.OutOfMemory;
    }

    std.debug.print("Parsed {d} points.\n", .{points.items.len});

    // -- Generate Edges --
    // We expect N^2 edges. For N=1000, 1M edges. For N=2000, 4M edges.
    // This fits easily in memory.
    var connections = std.ArrayList(Connection).initCapacity(allocator, 100) catch return Day8Error.OutOfMemory;
    // Ensure we have capacity to avoid reallocations
    const n = points.items.len;
    connections.ensureTotalCapacity(allocator, n * (n - 1) / 2) catch return Day8Error.OutOfMemory;

    for (0..n) |i| {
        for ((i + 1)..n) |j| {
            const dist = sqrDist(points.items[i], points.items[j]);
            connections.appendAssumeCapacity(Connection{
                .u = i,
                .v = j,
                .dist_sq = dist,
            });
        }
    }

    // -- Sort Edges --
    // Sort all edges by distance ascending
    std.mem.sort(Connection, connections.items, {}, Connection.lessThan);

    // -- Process Connections --
    var dsu = try DisjointSet.init(allocator, n);
    defer dsu.deinit();

    // Example result is after 10 so hard code that if this is not the input.
    const LIMIT = if (points.items.len == 1000 ) points.items.len else 10;
    const operations = @min(LIMIT, connections.items.len);

    std.debug.print("Processing top {d} shortest connections...\n", .{operations});

    for (0..operations) |i| {
        const conn = connections.items[i];
        // unionSets handles the logic: 
        // if they are already in the same set, it returns false (does nothing).
        // if they are different, it merges them and returns true.
        // We don't actually care about the return value here because the problem says 
        // "nothing happens" if they are already connected, but the operation 
        // still counts towards the 1000 limit.
        _ = dsu.unionSets(conn.u, conn.v);
    }

    // -- Calculate Results --
    // We need to group sizes by their root parent
    var final_sizes = std.ArrayList(u64).initCapacity(allocator, 1000) catch return Day8Error.OutOfMemory;
    
    // We can't just look at dsu.size array directly because strictly speaking
    // only dsu.size[root] is valid.
    // However, dsu.size is maintained correctly for roots.
    // We need to find the unique roots.
    var visited_roots = std.AutoHashMap(usize, void).init(allocator);

    for (0..n) |i| {
        const root = dsu.find(i);
        if (!visited_roots.contains(root)) {
            try visited_roots.put(root, {});
            final_sizes.append(allocator, dsu.size[root]) catch return Day8Error.OutOfMemory;
        }
    }

    // Sort sizes descending
    std.mem.sort(u64, final_sizes.items, {}, std.sort.desc(u64));

    std.debug.print("All circuit sizes ({d} circuits): ", .{final_sizes.items.len});
    for (final_sizes.items) |size| {
        std.debug.print("{d} ", .{size});
    }
    std.debug.print("\n", .{});

    // Multiply top 3
    var result: u64 = 1;
    for (0..3) |i| {
        if (i < final_sizes.items.len) {
            result *= final_sizes.items[i];
        }
    }

    std.debug.print("Answer: {d}\n", .{result});
}
