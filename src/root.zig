pub const backend = @import("backend");

pub const buttons = @import("elements/buttons.zig");
pub const dropdowns = @import("elements/dropdowns.zig");
pub const containers = @import("elements/containers.zig");
pub const sliders = @import("elements/sliders.zig");
pub const inputs = @import("elements/inputs.zig");

pub const grabbing = @import("grabbing");

// Gui elements
pub const Button = buttons.Button;
pub const ToggleButton = buttons.ToggleButton;
pub const FnButton = buttons.FnButton;

pub const Dropdown = dropdowns.Dropdown;
pub const EnumDropdown = dropdowns.EnumDropdown;

pub const Panel = containers.Panel;
pub const GroupBox = containers.GroupBox;

pub const Slider = sliders.Slider;

pub const TextInput = inputs.TextInput;
pub const ValueInput = inputs.ValueInput;
pub const ValueInputWithButtons = inputs.ValueInputWithButtons;

// Some useful backend stuffs
pub const Color = backend.Color;
pub const Rect = backend.Rect;
pub const Padding = backend.Padding;
pub const Vec2 = backend.Vec2;

pub const screenRect = backend.screenRect;

pub const State = enum { default, hovered, held, disabled };

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
    if (!backend.getMouseButtonState(.left).currently) {
        grabbing.held_element = null;
    }
}
