# Day 12: Christmas Tree Farm ⭐⭐

## Problem Summary

This is a polyomino packing problem. We have:
- A set of shapes (polyominoes) defined in the input
- Multiple rectangular regions to fill
- For each region, a list of how many of each shape need to fit

Shapes can be **rotated and flipped** to fit. Shapes cannot overlap (the `#` cells), but the empty cells (`.`) don't block other shapes.

## Goal

Count how many regions can successfully fit all their required shapes.

## Solutions

| Input | Expected | Actual | Status |
|-------|----------|--------|--------|
| example1.txt | 2 | 2 | ✅ |
| input.txt | 492 | 492 | ✅ |

## Part 2

Part 2 was not a coding challenge - it was the finale of Advent of Code 2025! Clicking "Finish Decorating the North Pole" awarded the final star.

## Examples

### Example 1 (example1.txt)

**Input:**
```
0:
###
##.
##.

1:
###
##.
.##

2:
.##
###
##.

3:
##.
###
##.

4:
###
#..
###

5:
###
.#.
###

4x4: 0 0 0 0 2 0
12x5: 1 0 1 0 2 2
12x5: 1 0 1 0 3 2
```

**Regions:**
1. `4x4: 0 0 0 0 2 0` - 4x4 region, needs 2 copies of shape 4 -> **CAN FIT**
2. `12x5: 1 0 1 0 2 2` - 12x5 region, needs 1 shape 0, 1 shape 2, 2 shape 4, 2 shape 5 -> **CAN FIT**
3. `12x5: 1 0 1 0 3 2` - Same as above but needs 3 of shape 4 instead of 2 -> **CANNOT FIT**

**Solution: 2**

## Algorithm

1. Parse shapes as sets of (row, col) coordinates
2. Generate all unique orientations (up to 8) for each shape via rotation and reflection
3. For each region:
   - Quick prune: if total shape area > region area, skip
   - Use backtracking to place shapes one by one
   - Try all positions and orientations for each shape
4. Count regions where all shapes can be placed

## Notes

- Shapes use `#` for filled cells and `.` for empty
- Each shape can have up to 8 unique orientations (4 rotations x 2 reflections)
- Shapes don't need to fill the entire region - they just need to fit without overlapping
