const std = @import("std");
const tokenizeScalar = std.mem.tokenizeScalar;

const ZigError = error{
    NoFileSupplied,
    FileNotFound,
    ParseFailed,
    OutOfMemory,
    OutOfBounds,
    NotPaper,
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

    // Read into a 2 dimensional array
    var rows = std.ArrayList([]u8).initCapacity(allocator, 100) catch return ZigError.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        const next_copy = try allocator.dupe(u8, next);
        _ = rows.append(allocator, next_copy) catch return ZigError.OutOfMemory;
    }

    var removed: usize = 0;
    draw_map(rows);
    while (true) {
        const papers = count_paper(allocator, rows) catch return ZigError.OutOfMemory;
        if (papers.len == 0) {
            break;
        }
        removed += papers.len;
        if (removed == 0) {
            break;
        }
        remove_paper(rows, papers);
        draw_map(rows);
    }
    std.debug.print("Result {d}.\n", .{ removed });
}

const Map = std.ArrayList([]u8);

const Paper = struct {
    row: usize,
    col: usize,
};

fn count_paper(allocator: std.mem.Allocator, map: Map) ZigError![]Paper {
    var list = try std.ArrayList(Paper).initCapacity(allocator, 100);
    errdefer list.deinit(allocator);

    for (map.items, 0..) |row_chars, r_idx| {
        for (row_chars, 0..) |char_at_col, c_idx| {
            if (char_at_col == '@') {
                const count = try count_neighbour_paper(map, @as(i32, @intCast(r_idx)), @as(i32, @intCast(c_idx)));
                if (count < 4) {
                    _ = list.append(allocator, Paper{ .row = r_idx, .col = c_idx }) catch return ZigError.OutOfMemory;
                }
            }
        }
    }
    return list.toOwnedSlice(allocator);
}

fn remove_paper(map: Map, papers: []const Paper) void {
    for (papers) |paper| {
        map.items[paper.row][paper.col] = 'x';
    }
}

fn draw_map(rows: Map) void {
    for (rows.items) |row| {
        std.debug.print("{s}\n", .{row});
    }
}

fn count_neighbour_paper(map: Map, row: i32, col: i32) ZigError!usize {
    // Check if row or col are negative before casting to usize
    if (row < 0 or col < 0) {
        return ZigError.OutOfBounds;
    }
    // Now safe to cast to usize for comparison with map dimensions
    const u_row = @as(usize, @intCast(row));
    const u_col = @as(usize, @intCast(col));

    if (u_row >= map.items.len or u_col >= map.items[u_row].len) {
        return ZigError.OutOfBounds;
    }

    if (map.items[u_row][u_col] != '@') return ZigError.NotPaper;

    var count: usize = 0;
    const directions = [_]i32{ -1, 0, 1 };

    for (directions) |dr| {
        for (directions) |dc| {
            if (dr == 0 and dc == 0) continue;

            const r_i32 = @as(i32, @intCast(row)) + dr;
            const c_i32 = @as(i32, @intCast(col)) + dc;

            if (r_i32 < 0 or r_i32 >= map.items.len) continue;
            const r = @as(usize, @intCast(r_i32));

            if (c_i32 < 0 or c_i32 >= map.items[r].len) continue;
            const c = @as(usize, @intCast(c_i32));

            if (map.items[r][c] == '@') {
                count += 1;
            }
        }
    }
    return count;
}

