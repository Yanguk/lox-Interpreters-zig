const std = @import("std");
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

    std.debug.print("Successfully Read {d} bytes:\n {s}", .{
        size,
        read_bytes,
    });
}

pub fn repl(io: Io) !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().readerStreaming(io, &stdin_buffer);

    const stdin = &stdin_reader.interface;

    while (true) {
        std.debug.print("> ", .{});

        const line = try stdin.takeDelimiter('\n');

        if (line) |content| {
            std.debug.print("DEBUG_💥[2826]: {s}:{d}: line={s}\n", .{ @src().file, @src().line, content });
        } else {
            break;
        }
    }
}

fn run() !void {
    std.debug.print("not yet implement!, fn run\n", .{});
}
