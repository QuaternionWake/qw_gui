const b = @import("backend");
const rl = @import("raylib");

parent: ?*const Self,

x: XPos,
y: YPos,

width: Width,
height: Height,

const Self = @This();

pub fn rlRect(self: Self) rl.Rectangle {
    const rect = self.vanillaRect();
    return .init(rect.x, rect.y, rect.width, rect.height);
}

// TODO: better name for this?
pub fn vanillaRect(self: Self) b.Rectangle {
    const parent = if (self.parent) |parent| parent.vanillaRect() else screenRect();

    const width = switch (self.width) {
        .amount => |val| val,
        .relative => |val| parent.width + val,
        .proportion => |val| parent.width * val,
        .max => parent.width,
    };

    const height = switch (self.height) {
        .amount => |val| val,
        .relative => |val| parent.height + val,
        .proportion => |val| parent.height * val,
        .max => parent.height,
    };

    const x = switch (self.x) {
        .left => |offset| parent.x + offset,
        .middle => |offset| parent.x + (parent.width - width) / 2 + offset,
        .right => |offset| parent.x + parent.width - width + offset,
    };

    const y = switch (self.y) {
        .top => |offset| parent.y + offset,
        .middle => |offset| parent.y + (parent.height - height) / 2 + offset,
        .bottom => |offset| parent.y + parent.height - height + offset,
    };

    return .init(x, y, width, height);
}

fn screenRect() b.Rectangle {
    const window_size = b.getWindowSize();
    return .{
        .x = 0,
        .y = 0,
        .width = window_size.x,
        .height = window_size.y,
    };
}

const XPos = union(enum) {
    left: f32,
    middle: f32,
    right: f32,
};

const YPos = union(enum) {
    top: f32,
    middle: f32,
    bottom: f32,
};

const Width = union(enum) {
    amount: f32,
    relative: f32,
    proportion: f32,
    max,
};

const Height = union(enum) {
    amount: f32,
    relative: f32,
    proportion: f32,
    max,
};
