const std = @import("std");
const aoc_utils = @import("aoc_utils");

const Point = struct {
    x: i64,
    y: i64,
};

const Edge = struct {
    p1: Point,
    p2: Point,
};

fn isInside(center_x2: i64, center_y2: i64, edges: []const Edge) bool {
    var winding_number: i64 = 0;
    
    // Ray cast to +infinity in X direction
    // Center is (center_x2 / 2.0, center_y2 / 2.0)
    // We check intersections with vertical edges
    
    for (edges) |edge| {
        // We only care about vertical edges for horizontal ray casting
        if (edge.p1.x == edge.p2.x) {
            const vx2 = edge.p1.x * 2;
            const vy1_2 = edge.p1.y * 2;
            const vy2_2 = edge.p2.y * 2;
            
            const min_y = @min(vy1_2, vy2_2);
            const max_y = @max(vy1_2, vy2_2);
            
            // Check if ray crosses the edge
            // Ray is at y = center_y2
            // Edge y range is [min_y, max_y) (standard convention)
            // Ray must be to the left of the edge (vx2 > center_x2)
            
            if (min_y <= center_y2 and center_y2 < max_y) {
                 if (vx2 > center_x2) {
                     // Determine direction for winding number if needed, 
                     // but for simple inside/outside, just counting odd/even is enough
                     // or winding number requires direction.
                     // Let's use simple odd/even rule (Jordan curve).
                     // But wait, "inside" a loop might technically require winding number if it loops multiple times?
                     // The problem implies a single loop "the list wraps".
                     // Even-odd rule is standard for point-in-polygon.
                     winding_number += 1;
                 }
            }
        }
    }
    
    return @mod(winding_number, 2) == 1;
}

fn intersectsInterior(rect_p1: Point, rect_p2: Point, edges: []const Edge) bool {
    const min_x = @min(rect_p1.x, rect_p2.x);
    const max_x = @max(rect_p1.x, rect_p2.x);
    const min_y = @min(rect_p1.y, rect_p2.y);
    const max_y = @max(rect_p1.y, rect_p2.y);

    for (edges) |edge| {
        if (edge.p1.x == edge.p2.x) {
            // Vertical edge
            const vx = edge.p1.x;
            const vy_min = @min(edge.p1.y, edge.p2.y);
            const vy_max = @max(edge.p1.y, edge.p2.y);
            
            // Check X overlap: strictly between
            if (vx > min_x and vx < max_x) {
                // Check Y overlap: intervals (vy_min, vy_max) and (min_y, max_y) must overlap
                // Overlap exists if max(start1, start2) < min(end1, end2)
                const overlap_start = @max(vy_min, min_y);
                const overlap_end = @min(vy_max, max_y);
                
                if (overlap_start < overlap_end) {
                    return true;
                }
            }
        } else {
            // Horizontal edge
            const hy = edge.p1.y;
            const hx_min = @min(edge.p1.x, edge.p2.x);
            const hx_max = @max(edge.p1.x, edge.p2.x);
            
             // Check Y overlap: strictly between
            if (hy > min_y and hy < max_y) {
                // Check X overlap
                const overlap_start = @max(hx_min, min_x);
                const overlap_end = @min(hx_max, max_x);
                
                if (overlap_start < overlap_end) {
                    return true;
                }
            }
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

    var points = try std.ArrayList(Point).initCapacity(allocator, 1000);
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

    if (points.items.len < 2) {
        std.debug.print("Not enough points\n", .{});
        return;
    }

    // Build edges
    var edges = try std.ArrayList(Edge).initCapacity(allocator, points.items.len);
    defer edges.deinit(allocator);

    for (0..points.items.len) |i| {
        const p1 = points.items[i];
        const p2 = points.items[(i + 1) % points.items.len];
        try edges.append(allocator, .{ .p1 = p1, .p2 = p2 });
    }
    
    // Verify edges are axis-aligned
    for (edges.items) |e| {
        if (e.p1.x != e.p2.x and e.p1.y != e.p2.y) {
            std.debug.print("Error: Edge not axis aligned: ({d},{d}) -> ({d},{d})\n", 
                .{e.p1.x, e.p1.y, e.p2.x, e.p2.y});
        }
    }

    var max_area: u64 = 0;
    const items = points.items;
    
    // Pre-calculate doubles for speed? Not strictly needed for logic but good for clarity in call
    // Logic: Loop all pairs, check inside
    
    for (items, 0..) |p1, i| {
        for (items[i + 1 ..]) |p2| {
            // Optimization: If area is smaller than max_area, we don't strictly need to check
            // but checking area is cheap.
            const width = @abs(p1.x - p2.x) + 1;
            const height = @abs(p1.y - p2.y) + 1;
            const area = width * height;
            
            if (area <= max_area) continue;

            // Check if valid
            // 1. Edges of polygon must not intersect interior of rectangle
            if (intersectsInterior(p1, p2, edges.items)) continue;
            
            // 2. Center must be inside
            const cx2 = p1.x + p2.x;
            const cy2 = p1.y + p2.y;
            if (isInside(cx2, cy2, edges.items)) {
                max_area = area;
            }
        }
    }

    std.debug.print("Max area: {d}\n", .{max_area});
}