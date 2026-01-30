const std = @import("std");
const path = @import("path.zig");

var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});
const stdout = &stdout_writer.interface;

pub fn main() !void {
    const builtin_keywords = .{ .{"exit"}, .{"echo"}, .{"type"} };
    const builtin_keywords_set = std.static_string_map.StaticStringMap(void).initComptime(builtin_keywords);

    var input_buffer: [2048]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().readerStreaming(&input_buffer);
    var stdin = &stdin_reader.interface;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    exit: while (true) {
        try stdout.print("$ ", .{});
        const input = try stdin.takeDelimiter('\n') orelse return; // terminate on EOF
        if (input.len == 0) {
            continue :exit;
        }

        if (std.mem.eql(u8, input, "exit")) {
            break :exit;
        }

        if (std.mem.startsWith(u8, input, "echo ")) {
            try stdout.print("{s}\n", .{input[5..]});
            continue :exit;
        }

        if (std.mem.startsWith(u8, input, "type ")) {
            const command = input[5..];
            if (builtin_keywords_set.has(command)) {
                try stdout.print("{s} is a shell builtin\n", .{command});
            } else {
                const result = try path.which(alloc, command); // todo: handle error
                if (result) |full_path| {
                    try stdout.print("{s} is {s}\n", .{ command, full_path });
                } else {
                    try stdout.print("{s}: not found\n", .{command});
                }
            }

            continue :exit;
        }

        try stdout.print("{s}: command not found\n", .{input});
    }
}
