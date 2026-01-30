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

    while (true) {
        try stdout.print("$ ", .{});
        const input = try stdin.takeDelimiter('\n') orelse return; // terminate on EOF
        // parse arguments and skip over whitespace
        var it = std.mem.splitAny(u8, input, " \t");
        var arg_list = try std.ArrayList([]const u8).initCapacity(alloc, 64);
        while (it.next()) |arg| {
            if (!std.mem.eql(u8, arg, "")) {
                try arg_list.append(alloc, arg);
            }
        }
        const args = try arg_list.toOwnedSlice(alloc);
        defer alloc.free(args);
        if (args.len == 0) {
            continue;
        }
        const command = args[0];

        if (std.mem.eql(u8, command, "exit")) {
            break;
        } else if (std.mem.eql(u8, command, "echo")) {
            for (args[1 .. args.len - 1]) |arg| {
                try stdout.print("{s} ", .{arg});
            }
            try stdout.print("{s}\n", .{args[args.len - 1]});
        } else if (std.mem.eql(u8, command, "type")) {
            std.debug.assert(args.len == 2);
            const arg = args[1];
            if (builtin_keywords_set.has(arg)) {
                try stdout.print("{s} is a shell builtin\n", .{arg});
            } else {
                const result = try path.which(alloc, arg);
                if (result) |full_path| {
                    try stdout.print("{s} is {s}\n", .{ arg, full_path });
                    alloc.free(full_path);
                } else {
                    try stdout.print("{s}: not found\n", .{arg});
                }
            }
        } else {
            const result = try path.which(alloc, command);
            if (result) |_| {
                var child = std.process.Child.init(args, alloc);
                _ = try child.spawnAndWait();
            } else {
                try stdout.print("{s}: command not found\n", .{input});
            }
        }
    }
}
