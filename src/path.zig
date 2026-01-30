const std = @import("std");
const builtin = @import("builtin");

pub fn which(alloc: std.mem.Allocator, exe: []const u8) !?[]const u8 {
    if (builtin.os.tag == .windows) {
        return error.UnsupportedPlatform;
    }
    const PATH = try std.process.getEnvVarOwned(alloc, "PATH");
    var iterator = std.mem.tokenizeScalar(u8, PATH, std.fs.path.delimiter);
    while (iterator.next()) |path| {
        // todo: follow symlinks?
        // todo: what if PATH contains relative paths?
        var dir = std.fs.openDirAbsolute(path, .{}) catch continue;
        defer dir.close();
        const stat = dir.statFile(exe) catch continue;
        if (fileIsExecutable(stat)) {
            return try constructFullPath(alloc, path, exe);
        }
    }
    return null;
}

fn fileIsExecutable(stat: std.fs.File.Stat) bool {
    const mode = stat.mode;
    const exe_permission = mode & 0o111;
    if (exe_permission != 0) {
        return true;
    } else {
        return false;
    }
}

fn constructFullPath(alloc: std.mem.Allocator, path: []const u8, name: []const u8) ![]u8 {
    const sep = [1]u8{std.fs.path.sep};
    return try std.mem.concat(alloc, u8, &[_][]const u8{ path, &sep, name });
}
