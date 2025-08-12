pub const buttons = @import("elements/buttons.zig");
pub const dropdowns = @import("elements/dropdowns.zig");

pub const grabbing = @import("gui-grabbing.zig");

pub fn updateGuiGlobals() void {
    grabbing.previous_held_element = grabbing.held_element;
    grabbing.previous_hovered_element = grabbing.hovered_element;
    grabbing.hovered_element = null;
}
