const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub fn main() !void {
    while (true) {
        try stdout.print("$ ", .{});

        var input_buffer: [2048]u8 = undefined;
        var stdin_reader = std.fs.File.stdin().readerStreaming(&input_buffer);
        var stdin = &stdin_reader.interface;
        const input = try stdin.takeDelimiter('\n') orelse return; // fixme: return on empty?
        const trimmed_input = std.mem.trim(u8, input, "\n");
        try stdout.print("{s}: command not found\n", .{trimmed_input});
    }
}
