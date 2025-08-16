const std = @import("std");
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const ascii = std.ascii;

const suffixes = [_][]const u8{ "", "k", "M", "B", "T", "Qa", "Qi" };

pub fn parseInt(T: type, string: []const u8) fmt.ParseIntError!T {
    if (string.len == 0) return error.InvalidCharacter;
    const decimal_point_idx = mem.indexOfScalar(u8, string, '.');
    const suffix_start = (mem.lastIndexOfAny(u8, string, "0123456789.") orelse return error.InvalidCharacter) + 1;

    const int_str, const dec_str = if (decimal_point_idx) |point| blk: {
        const last_nonzero = mem.lastIndexOfAny(u8, string, "123456789_.") orelse unreachable;
        break :blk if (last_nonzero == point) .{
            string[0..point],
            "",
        } else .{
            string[0..point],
            string[point + 1 .. last_nonzero + 1],
        };
    } else .{
        string[0..suffix_start],
        "",
    };
    if (mem.indexOfAny(u8, int_str, "0123456789") == null and mem.indexOfAny(u8, dec_str, "0123456789") == null)
        return error.InvalidCharacter;

    if (mem.indexOfNone(u8, int_str, "0123456789_+-") != null) return error.InvalidCharacter;
    if (mem.indexOfNone(u8, dec_str, "0123456789_") != null) return error.InvalidCharacter;

    const suffix = string[suffix_start..];

    const int_order_of_magnitude: usize = blk: {
        for (suffixes, 0..) |s, i| {
            if (ascii.eqlIgnoreCase(suffix, s)) break :blk i * 3;
        } else return error.InvalidCharacter;
    };
    const dec_order_of_magnitude = @as(isize, @intCast(int_order_of_magnitude)) - @as(isize, @intCast(dec_str.len));

    const int =
        if (int_str.len == 0 or int_str.len == 1 and (int_str[0] == '-' or int_str[0] == '+'))
            0
        else blk: {
            const val = try fmt.parseInt(T, int_str, 10);
            break :blk if (val != 0)
                val * (math.powi(T, 10, @intCast(int_order_of_magnitude)) catch return error.Overflow)
            else
                0;
        };
    const dec =
        if (dec_str.len == 0)
            0
        else if (dec_order_of_magnitude >= 0)
            try fmt.parseInt(T, dec_str, 10) * (math.powi(T, 10, @intCast(dec_order_of_magnitude)) catch return error.Overflow)
        else blk: {
            const end: usize = @intCast(@as(isize, @intCast(dec_str.len)) + dec_order_of_magnitude);
            const val = if (end == 0) 0 else try fmt.parseInt(T, dec_str[0..end], 10);
            const char_after = dec_str[end];
            break :blk if (char_after >= '5' and char_after <= '9')
                val + 1
            else
                val;
        };

    return if (string[0] == '-')
        math.sub(T, int, dec)
    else
        math.add(T, int, dec);
}

const t = std.testing;
test parseInt {
    try t.expectEqual(1234, parseInt(u32, "1234"));
    try t.expectEqual(1234, parseInt(i16, "1234"));
    try t.expectEqual(1234, parseInt(u32, "00001234"));
    try t.expectEqual(1234, parseInt(u32, "+1234"));
    try t.expectError(error.Overflow, parseInt(u32, "-1234"));
    try t.expectEqual(-1234, parseInt(i32, "-1234"));
    try t.expectEqual(1234, parseInt(u32, "1_234"));
    try t.expectEqual(1234, parseInt(u32, "1_2__3___4"));
    try t.expectEqual(1234, parseInt(u32, "+1_2__3___4"));
    try t.expectEqual(-1234, parseInt(i32, "-1_2__3___4"));
    try t.expectError(error.InvalidCharacter, parseInt(u32, "1.-234"));
    try t.expectError(error.InvalidCharacter, parseInt(u32, "1.+234"));

    try t.expectEqual(1234, parseInt(u32, "1234.0"));
    try t.expectEqual(1234, parseInt(u32, "1234.1"));
    try t.expectEqual(1235, parseInt(u32, "1234.5"));
    try t.expectEqual(1235, parseInt(u32, "1234.7"));

    try t.expectEqual(1234, parseInt(u32, "1.234k"));
    try t.expectEqual(1234, parseInt(u32, "0.001234M"));
    try t.expectEqual(1235, parseInt(u32, "0.0012345M"));
    try t.expectError(error.Overflow, parseInt(u32, "1234Qa"));
    try t.expectError(error.Overflow, parseInt(u32, "0.1234Qa"));
    try t.expectEqual(1234 * math.pow(u64, 10, 12), parseInt(u64, "1.234Qa"));
    try t.expectEqual(1_234_567_8 * math.pow(u64, 10, 11), parseInt(u64, "1234.5678Qa"));

    try t.expectEqual(-1234, parseInt(i32, "-1.234k"));
    try t.expectEqual(1, parseInt(i32, "0.5"));
    try t.expectEqual(-1, parseInt(i32, "-0.5"));
    try t.expectEqual(123, parseInt(i8, "0.123k"));
    try t.expectEqual(-123, parseInt(i8, "-0.123k"));
    try t.expectError(error.Overflow, parseInt(i8, "1.123k"));
    try t.expectEqual(1234, parseInt(u16, "0.000000000001234Qa"));
    try t.expectEqual(-1234, parseInt(i16, "-0.000000000001234Qa"));

    try t.expectEqual(1234, parseInt(u32, "1234."));
    try t.expectEqual(1234000, parseInt(u32, "1234.k"));
    try t.expectEqual(1, parseInt(u32, ".7"));
    try t.expectEqual(-1, parseInt(i32, "-.7"));
    try t.expectEqual(123, parseInt(u32, ".123k"));
    try t.expectEqual(-123, parseInt(i32, "-.123k"));
    try t.expectError(error.InvalidCharacter, parseInt(i32, "."));
    try t.expectError(error.InvalidCharacter, parseInt(i32, "-."));
    try t.expectError(error.InvalidCharacter, parseInt(i32, "+."));
    try t.expectError(error.InvalidCharacter, parseInt(i32, ".k"));
    try t.expectError(error.InvalidCharacter, parseInt(i32, "-.k"));

    try t.expectEqual(1234, parseInt(u32, "1.234K"));
    try t.expectEqual(1234000, parseInt(u32, "1234K"));
    try t.expectEqual(1234000, parseInt(u32, "1.234m"));
    try t.expectEqual(1234, parseInt(u32, "0.000000000001234Qa"));
}
