const std = @import("std");

const rl = @import("raylib");

pub const ElementID = struct {
    inner: u64,

    pub fn eql(lhs: ElementID, rhs: ?ElementID) bool {
        return if (rhs) |r|
            lhs.inner == r.inner
        else
            false;
    }
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
    return id.eql(held_element) or id.eql(previous_held_element);
}

pub fn hovering(id: ElementID) bool {
    return id.eql(hovered_element) or id.eql(previous_hovered_element);
}
