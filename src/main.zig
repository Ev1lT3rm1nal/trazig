const std = @import("std");

const tracy = @import("root.zig");

var count: usize = 0;

pub fn main() anyerror!void {
    const t = tracy.trace(@src(), null);
    defer t.end();

    std.log.info("All your codebase are belong to us.", .{});

    if (count >= 10) {
        return;
    }
    count += 1;

    var buf: [8]u8 = undefined;
    std.crypto.random.bytes(buf[0..]);
    const seed = std.mem.readInt(u64, buf[0..8], .little);
    var r = std.rand.DefaultPrng.init(seed);
    const w = r.random().int(u64);

    std.time.sleep(1000_000_000 * (w % 5));
    test_func();
    try main();
}

fn test_func() void {
    const t = tracy.trace(@src(), "test_func");
    defer t.end();

    std.debug.print("hiiii\n", .{});
}
