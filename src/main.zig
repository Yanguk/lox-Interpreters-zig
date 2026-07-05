const std = @import("std");
const Io = std.Io;

const zig_lox = @import("zig_lox");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    switch (args.len) {
        1 => try zig_lox.runPrompt(),
        2 => try zig_lox.runFile(args[1]),
        else => {
            std.debug.print("Usage: jlox [script]", .{});
            std.process.exit(64);
        },
    }
}
