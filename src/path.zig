const std = @import("std");
const builtin = @import("builtin");

pub fn which(alloc: std.mem.Allocator, command: []const u8) !?[]const u8 {
    if (builtin.os.tag == .windows) {
        return error.UnsupportedPlatform;
    }
    const PATH = try std.process.getEnvVarOwned(alloc, "PATH");
    defer alloc.free(PATH);
    var iterator = std.mem.tokenizeScalar(u8, PATH, std.fs.path.delimiter);
    while (iterator.next()) |path| {
        var abs_path: []const u8 = undefined;
        defer alloc.free(abs_path);
        if (!std.fs.path.isAbsolute(path)) {
            abs_path = try std.fs.cwd().realpathAlloc(alloc, path);
        } else {
            abs_path = path;
        }
        var dir = std.fs.openDirAbsolute(abs_path, .{}) catch continue;
        defer dir.close();
        const stat = dir.statFile(command) catch continue;
        if (fileIsExecutable(stat)) {
            return try constructFullPath(alloc, abs_path, command);
        }
    }
    return null;
}

fn fileIsExecutable(stat: std.fs.File.Stat) bool {
    const mode = stat.mode;
    const exe_permission = mode & 0o111;
    return exe_permission != 0;
}

fn constructFullPath(alloc: std.mem.Allocator, path: []const u8, command: []const u8) ![]u8 {
    const sep = [1]u8{std.fs.path.sep};
    return try std.mem.concat(alloc, u8, &[_][]const u8{ path, &sep, command });
}
