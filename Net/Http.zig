const std = @import("std");
const Io = std.Io;

pub fn headerVal(head: []const u8, name: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, head, '\n');
    var skipped = false;
    while (lines.next()) |line| {
        if (!skipped) {
            skipped = true;
            continue;
        }
        const pos = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        if (pos == 0) continue;
        if (std.ascii.eqlIgnoreCase(trim(line[0..pos]), name)) return trim(line[pos + 1 ..]);
    }
    return null;
}

fn trim(str: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = str.len;
    while (start < end and (str[start] == ' ' or str[start] == '\t' or str[start] == '\r')) : (start += 1) {}
    while (end > start and (str[end - 1] == ' ' or str[end - 1] == '\t' or str[end - 1] == '\r')) : (end -= 1) {}
    return str[start..end];
}

pub fn headEnd(data: []const u8) ?usize {
    if (std.mem.indexOf(u8, data, "\r\n\r\n")) |pos| return pos + 4;
    if (std.mem.indexOf(u8, data, "\n\n")) |pos| return pos + 2;
    return null;
}

pub fn contentLength(head: []const u8) usize {    const val = headerVal(head, "content-length") orelse return 0;
    return std.fmt.parseInt(usize, val, 10) catch 0;
}

pub fn respond(io: Io, stream: Io.net.Stream, body: []const u8, ctype: []const u8) !void {
    var sbuf: [1024]u8 = undefined;
    var out = stream.writer(io, &sbuf);
    try out.interface.print("HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\n\r\n", .{ ctype, body.len });
    try out.interface.writeAll(body);
    try out.interface.flush();
}
