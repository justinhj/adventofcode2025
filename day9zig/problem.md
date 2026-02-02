# Day 9: Movie Theater

## Problem Description

You land in the North Pole base movie theater! The movie theater has a big tile floor with an interesting pattern. Elves here are redecorating the theater by switching out some of the square tiles in the big grid they form. Some of the tiles are **red**; the Elves would like to find the largest rectangle that uses red tiles for two of its opposite corners.

### Part 1

You can choose any two red tiles as the opposite corners of your rectangle; your goal is to find the largest rectangle possible.

**Question:** Using two red tiles as opposite corners, what is the largest area of any rectangle you can make?

### Part 2

The Elves just remembered: they can only switch out tiles that are **red** or **green**. So, your rectangle can only include red or green tiles.

In your list, every red tile is connected to the red tile before and after it by a straight line of **green tiles**. The list wraps, so the first red tile is also connected to the last red tile. Tiles that are adjacent in your list will always be on either the same row or the same column.

In addition, all of the tiles **inside** this loop of red and green tiles are **also** green.

The rectangle you choose still must have red tiles in opposite corners, but any other tiles it includes must now be red or green. This significantly limits your options.

**Question:** Using two red tiles as opposite corners, what is the largest area of any rectangle you can make using only red and green tiles?

## Example

### Input
```
7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3
```

### Visualization
Red tiles as `#` and other tiles as `.`:
```
..............
.......#...#..
..............
..#....#......
..............
..#......#....
..............
.........#.#..
..............
```

### Part 2 Visualization
With green tiles marked as `X`:
```
..............
.......#XXX#..
.......XXXXX..
..#XXXX#XXXX..
..XXXXXXXXXX..
..#XXXXXX#XX..
.........XXX..
.........#X#..
..............
```

## Solutions

| Input | Part 1 Answer | Part 2 Answer |
|-------|---------------|---------------|
| example1.txt | 50 | 24 |
| input.txt | 4773451098 | 1429075575 |

## Algorithm Notes

### Part 1
For each pair of red tiles, calculate the area of the rectangle they form as opposite corners. Track the maximum area found.

### Part 2
- First, trace the polygon formed by the red tiles connected by green lines
- Determine which tiles are inside the polygon (flood fill or ray casting)
- For each pair of red tiles, check if all tiles in the rectangle are either red or green
- Track the maximum valid area
