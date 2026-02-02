# Advent of Code 2025 - Zig Solutions

This repository contains solutions for the Advent of Code 2025 challenges, implemented in the Zig programming language.

## Project Structure

The project is structured with a root build system and separate directories for each day's challenge.

*   `build.zig`: The central build configuration file. It dynamically creates build steps for each day and part.
*   `build.zig.zon`: Defines the project dependencies (currently none) and package metadata.
*   `common/`: Contains shared utility code.
    *   `aoc_utils.zig`: Provides helper functions for command-line argument parsing and file reading.
*   `dayXzig/`: Directories for each day (e.g., `day1zig`, `day2zig`).
    *   `src/`: Source code directory.
        *   `part1.zig`: Solution for Part 1.
        *   `part2.zig`: Solution for Part 2.
    *   `input.txt`: The puzzle input.
    *   `exampleX.txt`: Example inputs for testing.
*   `zig-out/`: The output directory for compiled binaries (generated after building).

## Building and Running

The project uses the Zig build system.

### Prerequisites

*   **Zig Compiler**: Version 0.15.2 or compatible.

### Build Commands

To build all executables (all days, both parts):

```bash
zig build
```

### Run Commands

To run a specific solution, use the following pattern:

```bash
zig build run-day<DAY>-part<PART> -- <INPUT_FILE>
```

**Examples:**

*   Run Day 1, Part 1 with the real input:
    ```bash
    zig build run-day1-part1 -- day1zig/input.txt
    ```

*   Run Day 7, Part 2 with an example input:
    ```bash
    zig build run-day7-part2 -- day7zig/example1.txt
    ```

The `--` separator is crucial to pass the file path argument to the executable instead of the build tool.

## Development Conventions

*   **Memory Management**:
    *   Use `std.heap.ArenaAllocator` wrapping `std.heap.page_allocator` for easy memory cleanup at the end of `main`.
    *   Pass the arena's allocator to functions that need to allocate memory.

*   **Input Handling**:
    *   Use `aoc_utils.getAndLoadInput(allocator)` to automatically retrieve the input filename from CLI args and load its content into memory.
    *   Input files are typically read fully into memory (up to 100KB limit in `aoc_utils`).

*   **Code Style**:
    *   Standard Zig formatting (`zig fmt`).
    *   `main` functions return `!void`.
    *   Error handling uses Zig's `try`, `catch`, and error union mechanisms.
    *   Debug printing is done via `std.debug.print`.

*   **New Day Setup**:
    1.  Create a new directory `dayXzig`.
    2.  Create `src/part1.zig` and `src/part2.zig`.
    3.  Import `std` and `aoc_utils`.
    4.  Implement `main` using the standard arena and input loading pattern.
    5.  The `build.zig` automatically detects days 1-12. If adding day 13+, update the `days` array in `build.zig`.

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

## Key Files

*   **`common/aoc_utils.zig`**:
    *   `getInputFileNameArg(allocator)`: Parses the first command-line argument.
    *   `loadInputFile(allocator, filename)`: Reads the file content.
    *   `getAndLoadInput(allocator)`: Combines the above two.

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

1. * *
2. * *
3. * *
4. * *
5. * *
6. * *
7. * *
8. * *
9.
10.
11.
12.

## You will use chrome dev tools to operate the advent of code site to solve puzzles

To see the current status:
https://adventofcode.com/2025

When the user asks which problem to work on next you can visit this site and find the first day without two stars. If all the days have 2 stars then there is no problem to work on. Otherwise tell the user the number of the next day.

## How to work on a day.

When the user wants you to work on a day do the following:
Click on the day in the main page on the website. 
Download the problem description to the days folder. eg day 1 is day1zig and save it as problem.md

Download the input text to the zig folder for the day and call it input.txt
https://adventofcode.com/2025/day/9/input

if there are one or more examples with solutions then save them as example1.txt, example2.txt 

in problem.md be sure to write the solution and each example so we can test them by running the program with the example filename and checking if the response matches the solution.

when you have gotten the examples and the input to match you can submit your answer on the page and check if the response is a success or not, otherwise follow the clue from the page. you may pause and ask for user assistance if you get into a loop.

During these steps update the problem.md with your steps. the user will check this file to see if you solved the puzzle and brief summary of steps as well as the aforementioned examples to solutions table.



