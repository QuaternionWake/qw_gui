const mem = @import("std").mem;

const b = @import("backend");

pub const MAX_ID_LEN = 64;

pub var hovered_buf: [MAX_ID_LEN]u8 = undefined;
pub var previous_hovered_buf: [MAX_ID_LEN]u8 = undefined;
pub var held_buf: [MAX_ID_LEN]u8 = undefined;
pub var previous_held_buf: [MAX_ID_LEN]u8 = undefined;

pub fn setId(buf: *[MAX_ID_LEN]u8, id: []const u8) usize {
    const len = @min(MAX_ID_LEN, id.len);
    @memcpy(buf[0..len], id[0..len]);
    return len;
}

pub fn idEql(lhs: []const u8, rhs: ?[]const u8) bool {
    return if (rhs) |r|
        mem.eql(u8, lhs, r)
    else
        false;
}

pub var hovered_element: ?[]const u8 = null;
pub var previous_hovered_element: ?[]const u8 = null;
pub var held_element: ?[]const u8 = null;
pub var previous_held_element: ?[]const u8 = null;

pub const InteractionInfo = struct { HoldInfo, HoverInfo, CanGrab };

pub const HoldInfo = packed struct {
    currently: bool,
    previously: bool,

    pub const grabbed: HoldInfo = .{ .currently = true, .previously = false };
    pub const released: HoldInfo = .{ .currently = false, .previously = true };
};

pub const HoverInfo = packed struct {
    currently: bool,
    previously: bool,

    pub const hovered: HoverInfo = .{ .currently = true, .previously = false };
    pub const unhovered: HoverInfo = .{ .currently = false, .previously = true };
};

pub const CanGrab = bool;

pub fn grabElement(id: []const u8) void {
    if (b.getMouseButtonState(.left).currently) {
        if (held_element == null) {
            const len = setId(&held_buf, id);
            held_element = held_buf[0..len];
        }
    } else {
        held_element = null;
    }
}

pub fn hoverElement(id: []const u8) void {
    if (hovered_element == null) {
        const len = setId(&hovered_buf, id);
        hovered_element = hovered_buf[0..len];
    }
}

pub fn getInteractionInfo(id: []const u8) InteractionInfo {
    return .{
        getHoldInfo(id),
        getHoverInfo(id),
        canGrab(id),
    };
}

pub fn getHoldInfo(id: []const u8) HoldInfo {
    return .{
        .currently = idEql(id, held_element),
        .previously = idEql(id, previous_held_element),
    };
}

pub fn getHoverInfo(id: []const u8) HoverInfo {
    return .{
        .currently = idEql(id, hovered_element),
        .previously = idEql(id, previous_hovered_element),
    };
}

pub fn canGrab(id: []const u8) bool {
    return idEql(id, held_element) or idEql(id, hovered_element) and held_element == null;
}
