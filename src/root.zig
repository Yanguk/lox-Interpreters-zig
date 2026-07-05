const std = @import("std");
const Io = std.Io;

pub fn runFile(path: []const u8) !void {
    std.debug.print("runFile, path: {s}\n", .{path});
}

pub fn runPrompt() !void {
    std.debug.print("not yet implement!, fn runPrompt\n", .{});

    return;
}

fn run() !void {
    std.debug.print("not yet implement!, fn run\n", .{});
}
