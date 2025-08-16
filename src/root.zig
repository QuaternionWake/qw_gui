const std = @import("std");
const rl = @import("raylib");

comptime {
    std.testing.refAllDecls(@import("utils/parsing.zig"));
}

pub const buttons = @import("elements/buttons.zig");
pub const dropdowns = @import("elements/dropdowns.zig");
pub const containers = @import("elements/containers.zig");
pub const sliders = @import("elements/sliders.zig");

pub const grabbing = @import("gui-grabbing.zig");

pub fn updateGuiGlobals() void {
    grabbing.previous_held_element = grabbing.held_element;
    grabbing.previous_hovered_element = grabbing.hovered_element;
    grabbing.hovered_element = null;
    if (!rl.isMouseButtonDown(.left)) {
        grabbing.held_element = null;
    }
}
