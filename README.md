# delay-line

A command line tool that prints all lines from stdin to stdout with
a fixed delay between each line.

## Examples

Print the date+time every second:

```sh
# Notice, this pipeline only ever launches 5 processes. It is also a
# a lot cleaner than the alternative "run date every second in a loop".
# Clean and efficient!
seq "$(date +%s)" 1 inf | sed 's/^/@/' | date -f - | delay-line 1s

# You can get more efficient by raising the delay.
seq "$(date +%s)" 10 inf | sed 's/^/@/' | date -f - | delay-line 10s

# This is useful for making your own status bar script for bars
# such as lemonbar.
```

## Build

External dependencies:
* [Zig `0.6.0`](https://ziglang.org/download/)


After getting the dependencies just clone the repo and its submodules and run:
```
zig build
```

All build artifacts will end up in `zig-cache/bin`.
See `zig build --help` for build options.

