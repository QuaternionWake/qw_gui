const std = @import("std");
const meta = std.meta;

const rl = @import("raylib");

pub const ElementID = struct {
    rect: rl.Rectangle,
};

pub var hovered_element: ?ElementID = null;
pub var previous_hovered_element: ?ElementID = null;
pub var held_element: ?ElementID = null;
pub var previous_held_element: ?ElementID = null;

pub fn grabElement(id: ElementID) void {
    if (rl.isMouseButtonDown(.left)) {
        if (held_element == null) {
            held_element = id;
        }
    } else {
        held_element = null;
    }
}

pub fn hoverElement(id: ElementID) void {
    if (hovered_element == null)
        hovered_element = id;
}

pub fn canGrab(id: ElementID) bool {
    return holding(id) or hovering(id) and held_element == null;
}

pub fn holding(id: ElementID) bool {
    return meta.eql(held_element, id) or meta.eql(previous_held_element, id);
}

pub fn hovering(id: ElementID) bool {
    return meta.eql(hovered_element, id) or meta.eql(previous_hovered_element, id);
}
