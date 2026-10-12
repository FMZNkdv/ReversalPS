const std = @import("std");
const Io = std.Io;
const heap = std.heap.page_allocator;
const Http = @import("Http.zig");
const log = std.debug.print;
const Message = @import("../Gate/Message.zig");

pub fn handleClient(io: Io, stream: Io.net.Stream) void {
    var conn = stream;
    defer conn.close(io);

    var acc: std.ArrayListUnmanaged(u8) = .empty;
    var tmp: [4096]u8 = undefined;

    while (true) {
        var bufs = [_][]u8{tmp[0..]};
        const got = conn.read(io, &bufs) catch return;
        if (got == 0) return;
        acc.appendSlice(heap, tmp[0..got]) catch return;
        const text = acc.items;
        const end = Http.headEnd(text);
        if (end == null and text.len <= 4096) continue;

        const hlen = end orelse text.len;
        const head = text[0..hlen];
        const path = headPath(head);
        const clen = Http.contentLength(head);

        if (text.len < hlen + clen) {
            if (text.len > 65536) return;
            continue;
        }

        const now = Io.Clock.real.now(io).toMilliseconds();
        const msg = Message.dispatch(heap, path, now) catch |err| {
            log("err {any}\n", .{err});
            return;
        };

        log("{s}\n", .{path});

        Http.respond(io, conn, msg.body, msg.ctype) catch return;
        const used = hlen + clen;
        const remain = text.len - used;
        std.mem.copyForwards(u8, acc.items[0..remain], text[used..]);
        acc.shrinkRetainingCapacity(remain);
    }
}

fn headPath(head: []const u8) []const u8 {
    var first: ?usize = null;
    for (head, 0..) |byte, idx| {
        if (byte == ' ' or byte == '\r' or byte == '\n') {
            first = idx;
            break;
        }
    }
    const start = first orelse return "/";
    var pos = start + 1;
    while (pos < head.len and head[pos] != ' ' and head[pos] != '\r' and head[pos] != '\n') : (pos += 1) {}
    var path = head[start + 1 .. pos];
    if (std.mem.indexOfScalar(u8, path, '?')) |cut| path = path[0..cut];
    return path;
}
