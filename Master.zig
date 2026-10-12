const std = @import("std");
const Io = std.Io;
const Session = @import("Net/Session.zig");
const log = std.debug.print;

const PORT: u16 = 3000;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const host = try Io.net.IpAddress.parse("0.0.0.0", PORT);
    var listener = try host.listen(io, .{ .reuse_address = true });
    defer listener.deinit(io);

    log("ReversalPS running in {d}!\n", .{PORT});

    while (true) {
        const conn = listener.accept(io) catch continue;
        const tread = std.Thread.spawn(.{}, Session.handleClient, .{ io, conn }) catch {
            var stream = conn;
            stream.close(io);
            continue;
        };
        _ = tread;
    }
}
