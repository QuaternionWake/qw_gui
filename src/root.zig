const std = @import("std");
const b = @import("backend");

comptime {
    std.testing.refAllDecls(@import("utils"));
}

pub const buttons = @import("elements/buttons.zig");
pub const dropdowns = @import("elements/dropdowns.zig");
pub const containers = @import("elements/containers.zig");
pub const sliders = @import("elements/sliders.zig");
pub const inputs = @import("elements/inputs.zig");

pub const grabbing = @import("grabbing");

pub const Color = b.Color;

pub fn updateGuiGlobals() void {
    if (grabbing.held_element) |held| {
        const len = grabbing.setId(&grabbing.previous_held_buf, held);
        grabbing.previous_held_element = grabbing.previous_held_buf[0..len];
    } else {
        grabbing.previous_held_element = null;
    }
    if (grabbing.hovered_element) |hovered| {
        const len = grabbing.setId(&grabbing.previous_hovered_buf, hovered);
        grabbing.previous_hovered_element = grabbing.previous_hovered_buf[0..len];
    } else {
        grabbing.previous_hovered_element = null;
    }

    grabbing.hovered_element = null;
    if (!b.getMouseButtonState(.left).currently) {
        grabbing.held_element = null;
    }
}
