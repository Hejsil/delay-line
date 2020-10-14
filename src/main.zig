const clap = @import("clap");
const std = @import("std");

const ascii = std.ascii;
const fmt = std.fmt;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
const process = std.process;
const time = std.time;

const Param = clap.Param(clap.Help);

const params = [_]Param{
    clap.parseParam("-d, --delay-first-line  Also have the delay before the first line.") catch unreachable,
    clap.parseParam("-h, --help              Display this help text and exit.") catch unreachable,
    Param{ .id = .{ .value = "TIME" }, .takes_value = .One },
};

fn usage(stream: var) !void {
    try stream.writeAll("Usage: delay-line ");
    try clap.usage(stream, &params);
    try stream.writeAll("\nCopies standard input to standard output with a fixed delay " ++
        "between each line.\n" ++
        "\n" ++
        "Options:\n");
    try clap.help(stream, &params);
}

pub fn main() !u8 {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut().outStream();
    const stderr = std.io.getStdErr().outStream();

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var args = clap.parse(clap.Help, &params, &arena.allocator) catch |err| {
        stderr.print("{}\n", .{err}) catch {};
        usage(stderr) catch {};
        return 1;
    };

    if (args.flag("--help")) {
        try usage(stdout);
        return 0;
    }

    const delay_first_line = args.flag("--delay-first-line");

    const pos = args.positionals();
    const time_per_line = str_to_time(if (pos.len > 0) pos[0] else "1") catch |err| {
        stderr.print("{}\n", .{err}) catch {};
        usage(stderr) catch {};
        return 1;
    };

    var start: usize = 0;
    var end: usize = 0;
    var buf: [1024]u8 = undefined;
    var timer = try time.Timer.start();
    var next_milestone = timer.read() + time_per_line;
    var first_line = true;
    done: while (true) : ({
        next_milestone += time_per_line;
        first_line = false;
    }) {
        while (!first_line or !delay_first_line) {
            if (mem.indexOfScalar(u8, buf[start..end], '\n')) |i| {
                try stdout.writeAll(buf[start..][0 .. i + 1]);
                start = start + i + 1;
                break;
            }

            try stdout.writeAll(buf[start..end]);
            start = 0;
            end = try stdin.read(&buf);
            if (end == 0)
                break :done;
        }

        while (math.sub(u64, next_milestone, timer.read())) |time_to_sleep| {
            time.sleep(time_to_sleep);
        } else |_| {}
    }

    return 0;
}

fn str_to_time(str: []const u8) !u64 {
    if (str.len == 0)
        return error.InvalidFormat;

    const suffix = mem.trimLeft(u8, str, "0123456789");
    const time_str = str[0 .. @ptrToInt(suffix.ptr) - @ptrToInt(str.ptr)];
    const res = try fmt.parseUnsigned(u64, time_str, 10);

    for ([_]struct { suffix: []const u8, scale: u64 }{
        .{ .suffix = "ns", .scale = time.nanosecond },
        .{ .suffix = "us", .scale = time.microsecond },
        .{ .suffix = "ms", .scale = time.millisecond },
        .{ .suffix = "s", .scale = time.second },
        .{ .suffix = "", .scale = time.second },
        .{ .suffix = "m", .scale = time.minute },
        .{ .suffix = "h", .scale = time.hour },
    }) |spec| {
        if (mem.eql(u8, suffix, spec.suffix))
            return res * spec.scale;
    }

    return error.InvalidFormat;
}
