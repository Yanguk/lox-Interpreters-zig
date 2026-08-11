const std = @import("std");
const scanner = @import("scanner.zig");
const Io = std.Io;

pub fn runFile(path: []const u8, io: Io, allocator: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();

    const file = try cwd.openFile(io, path, .{});
    defer file.close(io);

    const stat = try file.stat(io);
    const size = stat.size;

    var buffer: [1024]u8 = undefined;

    var file_reader = file.reader(io, &buffer);
    const reader = &file_reader.interface;

    const read_bytes = try reader.readAlloc(allocator, size);

    try run(read_bytes, allocator);
}

// repl
pub fn runPrompt(io: Io, allocator: std.mem.Allocator) !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().readerStreaming(io, &stdin_buffer);

    const stdin = &stdin_reader.interface;

    while (true) {
        std.debug.print("> ", .{});

        const line = try stdin.takeDelimiter('\n');

        if (line) |content| {
            try run(content, allocator);
            std.debug.print("\n", .{});
        } else {
            break;
        }
    }
}

// For now, just print the tokens.
fn run(source: []u8, allocator: std.mem.Allocator) !void {
    _ = allocator;

    var tokenIter = scanner.scan(source);

    while (tokenIter.next()) |token| {
        if (token.type == .Error) {
            logError(token.line, token.lexeme);

            std.process.exit(64);
        }

        std.debug.print("{s}\n", .{token.lexeme});
    }
}

var hadError = false;

fn logError(line: usize, message: []const u8) void {
    report(line, "", message);
}

fn report(line: usize, where: []u8, message: []const u8) void {
    std.debug.print("[line {d}] Error {s}: {s}", .{ line, where, message });
    hadError = true;
}
