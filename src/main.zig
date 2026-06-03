const std = @import("std");
const Io = std.Io;

const zig_lox = @import("zig_lox");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    if (args.len > 2) {
        std.debug.print("Usage: jlox [script]", .{});
        std.process.exit(64);

        return;
    }

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    if (args.len == 2) {
        const path: []const u8 = args[1];

        try zig_lox.runFile(path);

        return;
    }

    try zig_lox.runPrompt();
}
