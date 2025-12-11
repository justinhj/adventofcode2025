# Advent of Code 2025

Solutions to [Advent of Code 2025](https://adventofcode.com/2025) challenges written in Zig.

## Project Structure

- **Root build system** - Single `build.zig` compiles all days
- **Common utilities** - Shared file loading in `common/aoc_utils.zig`
- **Day folders** - Each day (day1zig through day12zig) contains:
  - `src/part1.zig` - Part 1 solution
  - `src/part2.zig` - Part 2 solution
  - `input.txt` - Puzzle input
  - `example1.txt` - Example/test input

## Requirements

- Zig 0.15.2 or later

Check your version:
```bash
zig version
```

## Building

Build all executables from the root directory:

```bash
zig build
```

This compiles all 24 executables (12 days × 2 parts) to `zig-out/bin/`.

## Running Solutions

Run any day's solution with:

```bash
zig build run-day1-part1 -- day1zig/input.txt
zig build run-day1-part1 -- day1zig/example1.txt
zig build run-day6-part2 -- day6zig/input.txt
```

Pattern: `zig build run-dayX-partY -- path/to/input.txt`

## Development

New solutions follow this pattern:

```zig
const std = @import("std");
const aoc_utils = @import("aoc_utils");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Load file from command-line argument
    const file_contents = aoc_utils.getAndLoadInput(allocator) catch {
        return;
    };

    // Your parsing and solution here
    std.debug.print("Solution: {d}\n", .{result});
}
```

The `aoc_utils` module handles all file I/O and command-line argument parsing, so you can focus on solving the puzzle.
