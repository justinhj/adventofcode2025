const std = @import("std");
const tokenizeScalar = std.mem.tokenizeScalar;
const aoc_utils = @import("aoc_utils");
const AocError = aoc_utils.AocError;

const Day8Error = error {
    ParseError,
} || AocError;

const CircuitEntry = struct {
    vector: [3]u64, 
    index: u64,
};

const CircuitDistance = struct {
    vec1: [3]u64, 
    vec2: [3]u64, 
    sqr_distance: u64,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file_contents = aoc_utils.getAndLoadInput(allocator) catch return Day8Error.FileNotFound;

    std.debug.print("Day 8 Part 1 - File size: {d} bytes\n", .{file_contents.len});

    var rows = std.ArrayList([]u64).initCapacity(allocator, 100) catch return Day8Error.OutOfMemory;
    var it = tokenizeScalar(u8, file_contents, '\n');
    while (it.next()) |next| {
        var it2 = tokenizeScalar(u8, next, ',');
        var row = allocator.alloc(u64, 3) catch return Day8Error.OutOfMemory;
        while (it2.next()) |next2| {
            for (0..3) |i| {
                row[i] = std.fmt.parseUnsigned(u64, next2, 10) catch return Day8Error.ParseError;
            }
        }
        rows.append(allocator, row) catch return Day8Error.ParseError;
    }

    // TODO
    // We want to join entries of vectors together starting with the ones nearest to each other, assign them all to circuits then 
    // return the biggest three circuits...
    // Modify the parsing code above to create rows of CircuitEntry. Set the circuit index to the max of u64 to indicate they have no assigned circuit
    // Write a function sqr_dist that calculates the squared straight line distance between two arrays of three as if they were vectors
    // work through the rows of circuit entries and add them to a priority queue that stores the 
    // rows of circuits entries and we want to populate with their circuit index so they must be indexed by value (vector)

    // now we use the struct called Distance that contains  = vec1, vec2, sqr dist
    // it needs a method for the priority queue comparison that sorts by dist

    // in order to populate the circuits create a priority queue that contains all pairs of cicuit values and their squared distance
    // the sort method for the priority queue is to minimize the sqr dist

    // now repeat until the pqueue is empty, pop the distance with the smallest dist
      // now lookup the circuitentries for both vectors and compare their circuit index
      // if they both have an index < int max do nothing
      // if one has an index < int then set the other one to the same index
      // if neither has an index then increment the circuit index and set them both to it

    // now you have the hashmap of circuit entry we want to make a second hashmap that maps circuit entries to counts
    // count all the circuit entries by putting them in the hashmap then iterate over that to find the biggest 3 circuits

    // To help in the above here is a sample priority queue and hashmap in zig

    // fn fScoreLessThan(context: void, a: fScoreEntry, b: fScoreEntry) Order {
    // _ = context;
    // return std.math.order(a.score, b.score);
// }

// const PQ = PriorityQueue(fScoreEntry, void, fScoreLessThan);


    // const os = std.AutoHashMap(Coord, bool).init(allocator);


    std.debug.print("row count {d}.\n", .{ rows.items.len });
}
