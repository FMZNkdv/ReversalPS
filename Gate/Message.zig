const std = @import("std");
const Version = @import("../Messages/Version.zig");
const Status = @import("../Messages/Status.zig");
const DisplayName = @import("../Messages/DisplayName.zig");
const Empty = @import("../Messages/Empty.zig");
const Account = @import("../Messages/Account.zig");
const SteamLogin = @import("../Messages/SteamLogin.zig");

fn wrap(alloc: std.mem.Allocator, data: []const u8) ![]u8 {
    return std.fmt.allocPrint(alloc, "{{\"code\":200,\"status\":\"OK\",\"data\":{s}}}", .{data});
}

pub const Resp = struct {
    body: []const u8,
    ctype: []const u8,
};

pub fn dispatch(alloc: std.mem.Allocator, path: []const u8, nowMs: i64) !Resp {
    if (std.mem.indexOf(u8, path, "version-info") != null) {
        return .{ .body = Version.body, .ctype = "application/json" };
    }
    if (std.mem.indexOf(u8, path, "load-account.php") != null or std.mem.indexOf(u8, path, "create-account.php") != null) {
        return .{ .body = Account.json, .ctype = "application/json" };
    }
    if (std.mem.indexOf(u8, path, "set-status.php") != null) {
        return .{ .body = Status.body, .ctype = "text/plain" };
    }
    if (std.mem.endsWith(u8, path, "/LoginWithSteam")) {
        var nbuf: [32]u8 = undefined;
        return .{ .body = try wrap(alloc, try SteamLogin.data(alloc, SteamLogin.isoNow(&nbuf, nowMs))), .ctype = "application/json" };
    }
    if (std.mem.endsWith(u8, path, "/UpdateUserTitleDisplayName")) {
        return .{ .body = try wrap(alloc, DisplayName.data), .ctype = "application/json" };
    }
    return .{ .body = try wrap(alloc, Empty.data), .ctype = "application/json" };
}
