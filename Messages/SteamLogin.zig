const std = @import("std");

fn twoDigits(buf: *[2]u8, val: i64) []const u8 {
    buf[0] = '0' + @as(u8, @intCast(@divFloor(val, 10)));
    buf[1] = '0' + @as(u8, @intCast(@mod(val, 10)));
    return buf;
}

pub fn isoNow(buf: *[32]u8, ms: i64) []const u8 {
    const secs: i64 = @divFloor(ms, 1000);
    const days: i64 = @divFloor(secs, 86400);
    const tod: i64 = secs - days * 86400;
    const absDay: i64 = days + 719468;
    const era: i64 = if (absDay >= 0) @divFloor(absDay, 146097) else @divFloor(absDay - 146096, 146097);
    const doe: i64 = absDay - era * 146097;
    const yoe: i64 = @divFloor(doe - @divFloor(doe, 1460) + @divFloor(doe, 36524) - @divFloor(doe, 146096), 365);
    const yr: i64 = yoe + era * 400;
    const doy: i64 = doe - (365 * yoe + @divFloor(yoe, 4) - @divFloor(yoe, 100));
    const mp: i64 = @divFloor(5 * doy + 2, 153);
    const day: i64 = doy - @divFloor(153 * mp + 2, 5) + 1;
    const month: i64 = if (mp < 10) mp + 3 else mp - 9;
    const year: i64 = if (month <= 2) yr + 1 else yr;
    var off: usize = 0;
    const ystr = std.fmt.bufPrint(buf[off..], "{d}", .{year}) catch return "";
    off += ystr.len;
    buf[off] = '-';
    off += 1;
    var b2: [2]u8 = undefined;
    @memcpy(buf[off .. off + 2], twoDigits(&b2, month));
    off += 2;
    buf[off] = '-';
    off += 1;
    @memcpy(buf[off .. off + 2], twoDigits(&b2, day));
    off += 2;
    buf[off] = 'T';
    off += 1;
    @memcpy(buf[off .. off + 2], twoDigits(&b2, @divFloor(tod, 3600)));
    off += 2;
    buf[off] = ':';
    off += 1;
    @memcpy(buf[off .. off + 2], twoDigits(&b2, @divFloor(@mod(tod, 3600), 60)));
    off += 2;
    buf[off] = ':';
    off += 1;
    @memcpy(buf[off .. off + 2], twoDigits(&b2, @mod(tod, 60)));
    off += 2;
    @memcpy(buf[off .. off + 5], ".000Z");
    off += 5;
    return buf[0..off];
}

pub fn data(alloc: std.mem.Allocator, now: []const u8) ![]u8 {
    return std.fmt.allocPrint(alloc, "{{\"SessionTicket\":\"000001\",\"PlayFabId\":\"000001\",\"NewlyCreated\":false,\"SettingsForUser\":{{\"NeedsAttribution\":false,\"GatherDeviceInfo\":false,\"GatherFocusInfo\":false}" ++
        "},\"LastLoginTime\":\"{s}\",\"InfoResultPayload\":{{\"AccountInfo\":{{\"PlayFabId\":\"000001\",\"Created\":\"{s}\",\"Username\":\"FMZNkdv\",\"TitleInfo\":{{\"DisplayName\":\"FMZNkdv\",\"Origination\":\"Stea" ++
        "m\",\"Created\":\"{s}\",\"LastLogin\":\"{s}\",\"FirstLogin\":\"{s}\",\"isBanned\":false,\"TitlePlayerAccount\":{{\"Id\":\"000001\",\"Type\":\"title_player_account\",\"TypeString\":\"title_player_account\"}}" ++
        "}},\"PrivateInfo\":{{}},\"SteamInfo\":{{\"SteamId\":\"76561199246929504\",\"SteamName\":\"FMZNkdv\"}}}},\"UserVirtualCurrency\":{{\"CO\":9999999,\"CR\":9999999,\"Coins\":9999999,\"Credits\":9999999,\"Gol" ++
        "d\":9999999}},\"UserVirtualCurrencyRechargeTimes\":{{}},\"UserData\":{{}},\"UserReadOnlyData\":{{}},\"CharacterList\":[],\"CharacterInventories\":[]}},\"EntityToken\":{{\"EntityToken\":\"_ENTIT" ++
        "Y_000001\",\"TokenExpiration\":\"2099-01-01T00:00:00Z\",\"Entity\":{{\"Id\":\"000001\",\"Type\":\"title_player_account\",\"TypeString\":\"title_player_account\"}}}},\"TreatmentAssignment\":{{\"Var" ++
        "iants\":[],\"Variables\":[]}}}}", .{ now, now, now, now, now });
}

// dump
