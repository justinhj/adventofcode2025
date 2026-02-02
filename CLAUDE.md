# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Advent of Code 2025 solutions written in Zig. Each day's challenge is in a separate directory (`day1zig/`, `day2zig/`, etc.) with a centralized build system at the root. A common utilities module (`common/aoc_utils.zig`) provides DRY file loading functionality.

## Development Commands

### Building and Running Solutions

All build commands are run from the **root directory**:

```bash
# Build all executables for all days
zig build

# Run a specific day and part with input file
zig build run-day1-part1 -- day1zig/input.txt
zig build run-day1-part1 -- day1zig/example1.txt
zig build run-day6-part2 -- day6zig/input.txt

# Pattern: zig build run-dayX-partY -- path/to/input.txt
```

**Important:** All executables require an input file path as the first command-line argument.

## Architecture Patterns

### Directory Structure

Root-level files:
```
.
├── build.zig              # Centralized build config for all days
├── build.zig.zon          # Package manifest
└── common/
    └── aoc_utils.zig      # Shared file loading utilities
```

Each day follows this structure:
```
dayXzig/
├── src/
│   ├── part1.zig          # Part 1 solution
│   └── part2.zig          # Part 2 solution
├── input.txt              # Full puzzle input (when available)
└── example1.txt           # Example/test input
```

### Code Structure Pattern

Every solution follows this consistent pattern:

1. **Imports:**
```zig
const std = @import("std");
const aoc_utils = @import("aoc_utils");
```

2. **Memory Management:** Arena allocator pattern:
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();
```

3. **Input Handling:** Use common utilities from `aoc_utils`:
```zig
// Get file contents from command-line arg
const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
    return;
};
```

The `aoc_utils` module provides:
- `getAndLoadInput()` - Combined function to get filename from args and load file
- `getInputFileNameArg()` - Get filename from command-line arguments
- `loadInputFile()` - Load file contents (100KB limit)
- `AocError` - Common error enum (NoFileSupplied, FileNotFound, OutOfMemory)

4. **Parsing and Solution:** Problem-specific parsing and computation

5. **Output:** Debug print for results: `std.debug.print("Solution: {d}\n", .{result});`

### Common Utilities

Solutions reuse these patterns:
- `std.mem.tokenizeScalar` for string splitting
- `std.ArrayList` for dynamic collections
- `std.fmt.parseUnsigned` / `std.fmt.parseInt` for number parsing
- `defer` for automatic cleanup

## Zig Version

Minimum required: **0.15.2**

Check with: `zig version`

## Development Workflow

1. Day folders (day1zig through day12zig) are pre-created with placeholder solutions
2. Placeholder solutions load the file and print size, ready for custom parsing
3. Solutions are developed incrementally (part 1, then part 2)
4. Commits are frequent and descriptive
5. Example inputs are tested before running against full input
6. All building and running happens from the root directory

## Code Style Notes

- Arena allocators eliminate manual memory management
- Error handling uses custom error enums specific to each problem
- Input validation returns early with clear error messages
- Comments explain non-obvious logic, especially algorithm steps
- Grid/2D problems often use `ArrayList(ArrayList(T))` structures
- Standard Zig formatting (`zig fmt`)
- `main` functions return `!void`
- Debug printing is done via `std.debug.print`

## Zig 0.15.2 Cheat Sheet

### Memory Allocation with ArenaAllocator
This is the standard pattern used in this project for easy memory cleanup.

```zig
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Use allocator for all dynamic allocations...
}
```

### ArrayList
Usage for dynamic arrays. Note that in this project/version, `append` takes the allocator.

```zig
const std = @import("std");
const aoc_utils = @import("aoc_utils");

// ... inside main or a function ...
    // Initialize with capacity
    var rows = std.ArrayList([]u8).initCapacity(allocator, 100) catch return aoc_utils.AocError.OutOfMemory;
    // defer rows.deinit(); // If not using arena

    // Appending items
    try rows.append(allocator, item);

    // Iterating
    for (rows.items) |row| {
        // ...
    }
```

### AutoHashMap
Usage for hash maps.

```zig
const std = @import("std");

// Define key and value types
const Position = struct {
    r: usize,
    c: usize,
};

// ... inside a function ...
    // Initialize
    var memo = std.AutoHashMap(Position, u64).init(allocator);
    defer memo.deinit();

    // Put (Insert/Update)
    try memo.put(pos, value);

    // Get (Retrieve) - returns ?Value (optional)
    if (memo.get(pos)) |cached_value| {
        return cached_value;
    }
```

## Unique Data Structures (Days 1-8)

### Day 2
- `Range`

### Day 3
- `MaxAndStart`

### Day 4
- `Paper`

### Day 5
- `Range`

### Day 7
- `Update`
- `BeamState`
- `Position`

### Day 8
- `Connection`
- `Point`
- `DisjointSet`

## Progress Tracker

1. ⭐⭐
2. ⭐⭐
3. ⭐⭐
4. ⭐⭐
5. ⭐⭐
6. ⭐⭐
7. ⭐⭐
8. ⭐⭐
9. ⭐⭐
10. ⭐⭐
11. ⭐⭐
12. ⭐⭐

**COMPLETE: 24/24 stars!**

## Chrome DevTools Workflow for Advent of Code

### Checking Status

To see the current status:
https://adventofcode.com/2025

When the user asks which problem to work on next, visit this site and find the first day without two stars. If all the days have 2 stars then there is no problem to work on. Otherwise tell the user the number of the next day.

### Working on a Day

When the user wants you to work on a day, do the following:

1. Click on the day in the main page on the website.
2. Download the problem description to the day's folder (e.g., day 1 is `day1zig`) and save it as `problem.md`.
3. Download the input text to the zig folder for the day and call it `input.txt`:
   - URL pattern: `https://adventofcode.com/2025/day/X/input`
4. If there are one or more examples with solutions, save them as `example1.txt`, `example2.txt`, etc.
5. In `problem.md`, be sure to write the solution and each example so we can test them by running the program with the example filename and checking if the response matches the solution.
6. When you have gotten the examples and the input to match, submit your answer on the page and check if the response is a success or not. Otherwise, follow the clue from the page.
7. You may pause and ask for user assistance if you get into a loop.
8. During these steps, update the `problem.md` with your steps. The user will check this file to see if you solved the puzzle and get a brief summary of steps as well as the aforementioned examples-to-solutions table.
