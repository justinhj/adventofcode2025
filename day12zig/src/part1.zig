const std = @import("std");
const aoc_utils = @import("aoc_utils");

const Coord = struct {
    row: i32,
    col: i32,
};

const Shape = struct {
    cells: []Coord,
    width: usize,
    height: usize,
    size: usize, // number of cells
};

const Region = struct {
    width: usize,
    height: usize,
    counts: []usize,
};

// Normalize shape so minimum row and col are 0
fn normalizeCoords(allocator: std.mem.Allocator, coords: []const Coord) ![]Coord {
    if (coords.len == 0) return try allocator.alloc(Coord, 0);

    var min_row: i32 = coords[0].row;
    var min_col: i32 = coords[0].col;
    for (coords) |c| {
        if (c.row < min_row) min_row = c.row;
        if (c.col < min_col) min_col = c.col;
    }

    var result = try allocator.alloc(Coord, coords.len);
    for (coords, 0..) |c, i| {
        result[i] = .{ .row = c.row - min_row, .col = c.col - min_col };
    }

    // Sort for consistent comparison
    std.mem.sort(Coord, result, {}, struct {
        fn lessThan(_: void, a: Coord, b: Coord) bool {
            if (a.row != b.row) return a.row < b.row;
            return a.col < b.col;
        }
    }.lessThan);

    return result;
}

// Rotate 90 degrees clockwise
fn rotate90(allocator: std.mem.Allocator, coords: []const Coord) ![]Coord {
    var rotated = try allocator.alloc(Coord, coords.len);
    for (coords, 0..) |c, i| {
        rotated[i] = .{ .row = c.col, .col = -c.row };
    }
    return normalizeCoords(allocator, rotated);
}

// Flip horizontally
fn flipH(allocator: std.mem.Allocator, coords: []const Coord) ![]Coord {
    var flipped = try allocator.alloc(Coord, coords.len);
    for (coords, 0..) |c, i| {
        flipped[i] = .{ .row = c.row, .col = -c.col };
    }
    return normalizeCoords(allocator, flipped);
}

fn coordsEqual(a: []const Coord, b: []const Coord) bool {
    if (a.len != b.len) return false;
    for (a, b) |ca, cb| {
        if (ca.row != cb.row or ca.col != cb.col) return false;
    }
    return true;
}

fn getMaxDimensions(coords: []const Coord) struct { width: usize, height: usize } {
    var max_row: i32 = 0;
    var max_col: i32 = 0;
    for (coords) |c| {
        if (c.row > max_row) max_row = c.row;
        if (c.col > max_col) max_col = c.col;
    }
    return .{
        .width = @intCast(max_col + 1),
        .height = @intCast(max_row + 1),
    };
}

// Generate all unique orientations (rotations and reflections)
fn generateOrientations(allocator: std.mem.Allocator, base_coords: []const Coord) ![]Shape {
    var orientations = try std.ArrayList(Shape).initCapacity(allocator, 8);

    var current = try normalizeCoords(allocator, base_coords);

    // Try all 4 rotations
    for (0..4) |_| {
        // Check if this orientation is already in list
        var found = false;
        for (orientations.items) |existing| {
            if (coordsEqual(existing.cells, current)) {
                found = true;
                break;
            }
        }
        if (!found) {
            const dims = getMaxDimensions(current);
            try orientations.append(allocator, .{
                .cells = current,
                .width = dims.width,
                .height = dims.height,
                .size = current.len,
            });
        }

        // Also try flipped version
        const flipped = try flipH(allocator, current);
        found = false;
        for (orientations.items) |existing| {
            if (coordsEqual(existing.cells, flipped)) {
                found = true;
                break;
            }
        }
        if (!found) {
            const dims = getMaxDimensions(flipped);
            try orientations.append(allocator, .{
                .cells = flipped,
                .width = dims.width,
                .height = dims.height,
                .size = flipped.len,
            });
        }

        current = try rotate90(allocator, current);
    }

    return orientations.items;
}

fn parseInput(allocator: std.mem.Allocator, content: []const u8) !struct {
    shape_orientations: [][]Shape,
    shape_sizes: []usize, // Size (# of cells) for each shape type
    regions: []Region,
} {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    // Parse shapes
    var shape_bases = try std.ArrayList([]Coord).initCapacity(allocator, 10);
    var current_shape_coords = try std.ArrayList(Coord).initCapacity(allocator, 10);
    var current_row: i32 = 0;

    while (lines.next()) |line| {
        // Check if this is a region line (contains 'x')
        if (std.mem.indexOf(u8, line, "x") != null) {
            // Save last shape if any
            if (current_shape_coords.items.len > 0) {
                const coords = try allocator.dupe(Coord, current_shape_coords.items);
                try shape_bases.append(allocator, coords);
                current_shape_coords.clearRetainingCapacity();
            }
            // Put the line back for region parsing
            var region_lines = try std.ArrayList([]const u8).initCapacity(allocator, 1000);
            try region_lines.append(allocator, line);
            while (lines.next()) |region_line| {
                try region_lines.append(allocator, region_line);
            }

            // Generate all orientations for each shape
            var shape_orientations = try allocator.alloc([]Shape, shape_bases.items.len);
            var shape_sizes = try allocator.alloc(usize, shape_bases.items.len);
            for (shape_bases.items, 0..) |base, i| {
                shape_orientations[i] = try generateOrientations(allocator, base);
                shape_sizes[i] = base.len;
            }

            // Parse regions
            var regions = try std.ArrayList(Region).initCapacity(allocator, 1000);
            for (region_lines.items) |region_line| {
                // Format: WxH: c0 c1 c2 c3 c4 c5
                var parts = std.mem.tokenizeScalar(u8, region_line, ':');
                const dims_str = parts.next() orelse continue;
                const counts_str = parts.next() orelse continue;

                // Parse dimensions
                var dim_parts = std.mem.tokenizeScalar(u8, dims_str, 'x');
                const width = std.fmt.parseUnsigned(usize, dim_parts.next() orelse continue, 10) catch continue;
                const height = std.fmt.parseUnsigned(usize, dim_parts.next() orelse continue, 10) catch continue;

                // Parse counts
                var counts = try std.ArrayList(usize).initCapacity(allocator, 10);
                var count_parts = std.mem.tokenizeScalar(u8, counts_str, ' ');
                while (count_parts.next()) |count_str| {
                    const count = std.fmt.parseUnsigned(usize, count_str, 10) catch continue;
                    try counts.append(allocator, count);
                }

                try regions.append(allocator, .{
                    .width = width,
                    .height = height,
                    .counts = counts.items,
                });
            }

            return .{
                .shape_orientations = shape_orientations,
                .shape_sizes = shape_sizes,
                .regions = regions.items,
            };
        }

        // Check if this is a shape header (digit followed by colon)
        if (line.len >= 2 and line[line.len - 1] == ':') {
            // Save previous shape if any
            if (current_shape_coords.items.len > 0) {
                const coords = try allocator.dupe(Coord, current_shape_coords.items);
                try shape_bases.append(allocator, coords);
                current_shape_coords.clearRetainingCapacity();
            }
            current_row = 0;
        } else {
            // Shape row
            for (line, 0..) |ch, col| {
                if (ch == '#') {
                    try current_shape_coords.append(allocator, .{
                        .row = current_row,
                        .col = @intCast(col),
                    });
                }
            }
            current_row += 1;
        }
    }

    // This shouldn't happen with valid input
    return error.InvalidInput;
}

// Find first empty cell (row-major order)
fn findFirstEmpty(grid: [][]bool) ?struct { row: usize, col: usize } {
    for (grid, 0..) |row_data, row| {
        for (row_data, 0..) |cell, col| {
            if (!cell) return .{ .row = row, .col = col };
        }
    }
    return null;
}

// Check if shape can be placed at position
fn canPlace(grid: [][]bool, shape: Shape, start_row: usize, start_col: usize) bool {
    const grid_height = grid.len;
    const grid_width = grid[0].len;

    for (shape.cells) |cell| {
        const row = start_row + @as(usize, @intCast(cell.row));
        const col = start_col + @as(usize, @intCast(cell.col));

        if (row >= grid_height or col >= grid_width) return false;
        if (grid[row][col]) return false;
    }
    return true;
}

// Place shape on grid
fn placeShape(grid: [][]bool, shape: Shape, start_row: usize, start_col: usize) void {
    for (shape.cells) |cell| {
        const row = start_row + @as(usize, @intCast(cell.row));
        const col = start_col + @as(usize, @intCast(cell.col));
        grid[row][col] = true;
    }
}

// Remove shape from grid
fn removeShape(grid: [][]bool, shape: Shape, start_row: usize, start_col: usize) void {
    for (shape.cells) |cell| {
        const row = start_row + @as(usize, @intCast(cell.row));
        const col = start_col + @as(usize, @intCast(cell.col));
        grid[row][col] = false;
    }
}

// Shape instance: which shape type and how many remaining
const ShapeInstance = struct {
    shape_type: usize,
    remaining: usize,
};

// Backtracking solver - place all shapes one by one
fn solveAllShapes(
    grid: [][]bool,
    shape_orientations: [][]Shape,
    shapes: []ShapeInstance,
    shape_type_idx: usize,
) bool {
    // Find next shape type that needs placing
    var idx = shape_type_idx;
    while (idx < shapes.len and shapes[idx].remaining == 0) {
        idx += 1;
    }

    if (idx >= shapes.len) {
        return true; // All shapes placed!
    }

    const orientations = shape_orientations[shapes[idx].shape_type];
    const grid_height = grid.len;
    const grid_width = grid[0].len;

    // Try each orientation
    for (orientations) |orientation| {
        if (orientation.height > grid_height or orientation.width > grid_width) continue;

        // Try each position
        for (0..(grid_height - orientation.height + 1)) |row| {
            for (0..(grid_width - orientation.width + 1)) |col| {
                if (canPlace(grid, orientation, row, col)) {
                    placeShape(grid, orientation, row, col);
                    shapes[idx].remaining -= 1;

                    if (solveAllShapes(grid, shape_orientations, shapes, idx)) {
                        return true;
                    }

                    shapes[idx].remaining += 1;
                    removeShape(grid, orientation, row, col);
                }
            }
        }
    }

    return false;
}

fn canFitRegion(allocator: std.mem.Allocator, region: Region, shape_orientations: [][]Shape, shape_sizes: []const usize) !bool {
    // Quick area check: total shape area must fit within region
    var total_shape_area: usize = 0;
    for (region.counts, 0..) |count, i| {
        total_shape_area += count * shape_sizes[i];
    }

    const region_area = region.width * region.height;
    if (total_shape_area > region_area) {
        return false; // Can't possibly fit
    }

    // Create grid
    var grid = try allocator.alloc([]bool, region.height);
    for (0..region.height) |i| {
        grid[i] = try allocator.alloc(bool, region.width);
        @memset(grid[i], false);
    }

    // Build shape instances
    var shapes = try allocator.alloc(ShapeInstance, region.counts.len);
    for (region.counts, 0..) |count, i| {
        shapes[i] = .{ .shape_type = i, .remaining = count };
    }

    return solveAllShapes(grid, shape_orientations, shapes, 0);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    const parsed = try parseInput(allocator, file_contents);

    var count: usize = 0;
    for (parsed.regions, 0..) |region, i| {
        // Create a child arena for each region to avoid memory bloat
        var region_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer region_arena.deinit();

        if (try canFitRegion(region_arena.allocator(), region, parsed.shape_orientations, parsed.shape_sizes)) {
            count += 1;
        }

        if ((i + 1) % 100 == 0) {
            std.debug.print("Processed {d} regions...\n", .{i + 1});
        }
    }

    std.debug.print("Solution: {d}\n", .{count});
}
