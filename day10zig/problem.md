# Day 10: Factory

## Problem Description

You find a large factory where the machines are all offline, and none of the Elves can figure out the initialization procedure. The manual sections detailing the initialization procedure were eaten by a Shiba Inu. All that remains are indicator light diagrams, button wiring schematics, and joltage requirements for each machine.

### Input Format

Each line describes one machine:
- `[.##.]` - Indicator light diagram in square brackets (`.` = off, `#` = on)
- `(0,1,2)` - Button wiring schematics in parentheses (indices of lights/counters affected)
- `{3,5,4,7}` - Joltage requirements in curly braces

### Part 1

To start a machine, its **indicator lights** must match those shown in the diagram. All indicator lights are **initially off**.

You can **toggle** the state of indicator lights by pushing buttons. Each button lists which indicator lights it toggles. When you push a button, each listed indicator light either turns on (if off) or turns off (if on).

**Question:** What is the fewest button presses required to correctly configure the indicator lights on all of the machines?

### Part 2

Now worry about the joltage requirements. Each machine has **numeric counters** tracking joltage levels, all **initially set to zero**.

The button wiring schematics now indicate which counters are affected. When you push a button, each listed counter is **increased by 1**.

**Question:** What is the fewest button presses required to correctly configure the joltage level counters on all of the machines?

## Example

### Input
```
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
```

### Part 1 Walkthrough

**Machine 1:** `[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}`
- Target: lights 1 and 2 ON, lights 0 and 3 OFF
- Solution: Press `(0,2)` and `(0,1)` once each = **2 presses**

**Machine 2:** `[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}`
- Target: light 3 ON, all others OFF
- Solution: Press `(0,4)`, `(0,1,2)`, and `(1,2,3,4)` once each = **3 presses**

**Machine 3:** `[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}`
- Target: lights 1,2,3,5 ON; lights 0,4 OFF
- Solution: Press `(0,3,4)` and `(0,1,2,4,5)` once each = **2 presses**

**Total:** 2 + 3 + 2 = **7**

### Part 2 Walkthrough

**Machine 1:** Target counters `{3,5,4,7}`
- Solution: Press `(3)` 1x, `(1,3)` 3x, `(2,3)` 3x, `(0,2)` 1x, `(0,1)` 2x = **10 presses**

**Machine 2:** Target counters `{7,5,12,7,2}`
- Solution: Press `(0,2,3,4)` 2x, `(2,3)` 5x, `(0,1,2)` 5x = **12 presses**

**Machine 3:** Target counters `{10,11,11,5,10,5}`
- Solution: Press `(0,1,2,3,4)` 5x, `(0,1,2,4,5)` 5x, `(1,2)` 1x = **11 presses**

**Total:** 10 + 12 + 11 = **33**

## Solutions

| Input | Part 1 Answer | Part 2 Answer |
|-------|---------------|---------------|
| example1.txt | 7 | 33 |
| input.txt | 417 | 16765 |

## Algorithm Notes

### Part 1
This is a system of linear equations over GF(2) (binary field). Each button press toggles certain lights. We need to find a combination of button presses (0 or 1 each, since pressing twice cancels out) that achieves the target state.

Use Gaussian elimination over GF(2) to solve. The minimum number of presses is the number of buttons with coefficient 1 in the solution.

### Part 2
This is a system of linear equations over integers. We need to find non-negative integer coefficients for each button such that the weighted sum of affected counters equals the target values.

This is an Integer Linear Programming problem. Minimize the sum of coefficients subject to the constraint that each counter reaches its target value.
