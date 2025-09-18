const std = @import("std");
const rl = @import("raylib");

comptime {
    std.testing.refAllDecls(@import("utils"));
}

pub const buttons = @import("elements/buttons.zig");
pub const dropdowns = @import("elements/dropdowns.zig");
pub const containers = @import("elements/containers.zig");
pub const sliders = @import("elements/sliders.zig");
pub const inputs = @import("elements/inputs.zig");

pub const grabbing = @import("grabbing");

pub fn updateGuiGlobals() void {
    grabbing.previous_held_element = grabbing.held_element;
    grabbing.previous_hovered_element = grabbing.hovered_element;
    grabbing.hovered_element = null;
    if (!rl.isMouseButtonDown(.left)) {
        grabbing.held_element = null;
    }
}
