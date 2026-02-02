# Day 11: Reactor

## Part 1

Find all paths from `you` to `out` in a directed graph of devices.

Each line gives a device name followed by the devices its outputs connect to. Data flows only forward through outputs.

### Example 1

| Input | Expected Output |
|-------|-----------------|
| example1.txt | 5 |

The 5 paths from `you` to `out`:
1. you -> bbb -> ddd -> ggg -> out
2. you -> bbb -> eee -> out
3. you -> ccc -> ddd -> ggg -> out
4. you -> ccc -> eee -> out
5. you -> ccc -> fff -> out

### Part 1 Solution

**Answer: 636** ✓

---

## Part 2

Now find paths from `svr` (server rack) to `out` that visit **both** `dac` (digital-to-analog converter) and `fft` (fast Fourier transform) in any order.

### Example 2

| Input | Expected Output |
|-------|-----------------|
| example2.txt | 2 |

All 8 paths from `svr` to `out`:
- svr,aaa,fft,ccc,ddd,hub,fff,ggg,out
- svr,aaa,fft,ccc,ddd,hub,fff,hhh,out
- svr,aaa,**fft**,ccc,eee,**dac**,fff,ggg,out ✓
- svr,aaa,**fft**,ccc,eee,**dac**,fff,hhh,out ✓
- svr,bbb,tty,ccc,ddd,hub,fff,ggg,out
- svr,bbb,tty,ccc,ddd,hub,fff,hhh,out
- svr,bbb,tty,ccc,eee,dac,fff,ggg,out (only has dac)
- svr,bbb,tty,ccc,eee,dac,fff,hhh,out (only has dac)

Only 2 paths visit both `fft` and `dac`.

### Part 2 Solution

**Answer: TBD**

---

## Progress

- [x] Part 1 complete
- [ ] Part 2 in progress
