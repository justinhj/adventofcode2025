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
    const LIMIT = if (points.items.len == 1000) points.items.len else 10;
    const operations = @min(LIMIT, connections.items.len);

    std.debug.print("Processing top {d} shortest connections...\n", .{operations});

    // Track number of distinct circuits (starts at n, decreases by 1 each successful union)
    var num_circuits: usize = n;

    for (0..operations) |i| {
        const conn = connections.items[i];
        if (dsu.unionSets(conn.u, conn.v)) {
            num_circuits -= 1;
        }
    }

    std.debug.print("After initial {d} operations: {d} circuits remain\n", .{ operations, num_circuits });

    // Continue processing until we have exactly 1 circuit
    var final_conn: Connection = undefined;
    var conn_index: usize = operations;

    while (num_circuits > 1 and conn_index < connections.items.len) {
        const conn = connections.items[conn_index];
        if (dsu.unionSets(conn.u, conn.v)) {
            num_circuits -= 1;
            if (num_circuits == 1) {
                final_conn = conn;
                std.debug.print("Final merge at connection index {d}\n", .{conn_index});
            }
        }
        conn_index += 1;
    }

    // Get the two points that formed the final connection
    const point_u = points.items[final_conn.u];
    const point_v = points.items[final_conn.v];

    std.debug.print("Final connection between:\n", .{});
    std.debug.print("  Point U: ({d},{d},{d})\n", .{ point_u.x, point_u.y, point_u.z });
    std.debug.print("  Point V: ({d},{d},{d})\n", .{ point_v.x, point_v.y, point_v.z });

    // Multiply X coordinates
    const result: i64 = point_u.x * point_v.x;

    std.debug.print("Answer: {d}\n", .{result});
}
