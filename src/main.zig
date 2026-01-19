const std = @import("std");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub fn main() !void {
    const keywords = .{ .{"exit"}, .{"echo"}, .{"type"} }; // todo: improve list of tuple construction
    // var keywords_buffer: [2048]u8 = undefined;
    // var keywords_allocator = std.heap.FixedBufferAllocator.init(&keywords_buffer);
    const keywords_map = std.static_string_map.StaticStringMap(void).initComptime(keywords);

    var input_buffer: [2048]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().readerStreaming(&input_buffer);
    var stdin = &stdin_reader.interface;

    exit: while (true) {
        try stdout.print("$ ", .{});
        const input = try stdin.takeDelimiter('\n') orelse return; // fixme: what to do on empty input?
        const trimmed_input = std.mem.trim(u8, input, "\n");

        if (std.mem.eql(u8, trimmed_input, "exit")) {
            break :exit;
        }

        if (std.mem.startsWith(u8, trimmed_input, "echo ")) {
            try stdout.print("{s}\n", .{trimmed_input[5..]});
            continue :exit;
        }

        if (std.mem.startsWith(u8, trimmed_input, "type ")) {
            const command = trimmed_input[5..];
            if (keywords_map.has(command)) {
                try stdout.print("{s} is a shell builtin\n", .{command});
            } else {
                try stdout.print("{s}: not found\n", .{command});
            }
            continue :exit;
        }

        try stdout.print("{s}: command not found\n", .{trimmed_input});
    }
}
