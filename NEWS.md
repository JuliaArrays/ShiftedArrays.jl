## ShiftedArrays 0.3 release notes

### Breaking changes

- Removed the `dim` keyword: instead of e.g. `lag(v, 3, dim = 2)` write `lag(v, (0, 3))` (in agreement with `circshift` from Julia Base)
- Changed direction of shifting for `ShiftedArray` and `CircShiftedArray` constructors. For example `CircShiftedArray(v, n)` with a positive `n` shifts to the right (in agreement with `circshift(v, n)` from Julia Base).

## New features

- `CircShiftedArray` type to shift arrays circularly.
- A lazy version of `circshift`: `ShiftedArray.circshift`
