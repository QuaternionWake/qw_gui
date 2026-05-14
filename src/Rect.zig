const b = @import("backend");
const Rectangle = b.Rectangle;

pub fn newRect(parent: ?Rectangle, x: XPos, y: YPos, width: Width, height: Height) Rectangle {
    const parent_ = parent orelse screenRect();

    const width_ = switch (width) {
        .amount => |val| val,
        .relative => |val| parent_.width + val,
        .proportion => |val| parent_.width * val,
        .max => parent_.width,
    };

    const height_ = switch (height) {
        .amount => |val| val,
        .relative => |val| parent_.height + val,
        .proportion => |val| parent_.height * val,
        .max => parent_.height,
    };

    const x_ = switch (x) {
        .left => |offset| parent_.x + offset,
        .middle => |offset| parent_.x + (parent_.width - width) / 2 + offset,
        .right => |offset| parent_.x + parent_.width - width + offset,
    };

    const y_ = switch (y) {
        .top => |offset| parent_.y + offset,
        .middle => |offset| parent_.y + (parent_.height - height) / 2 + offset,
        .bottom => |offset| parent_.y + parent_.height - height + offset,
    };

    return .init(x_, y_, width_, height_);
}

pub fn nthSubrectV(parent: ?Rectangle, n: usize, options: SubrectOptions) Rectangle {
    var result = options.padding.subrect(parent orelse screenRect());
    result.height = (result.height + options.gap) / options.total_subrects;
    result.y += result.height * n;
    result.height -= options.gap;
    return result;
}

pub fn nthSubrectH(parent: ?Rectangle, n: usize, options: SubrectOptions) Rectangle {
    var result = options.padding.subrect(parent orelse screenRect());
    result.width = (result.width + options.gap) / options.total_subrects;
    result.x += result.width * n;
    result.width -= options.gap;
    return result;
}

const SubrectOptions = struct {
    total_subrects: usize,
    padding: Padding,
    gap: f32,
};

pub fn gridSubrect(parent: ?Rectangle, x: usize, y: usize, options: GridSubrectOptions) Rectangle {
    var result = options.padding.subrect(parent orelse screenRect());
    result.width = (result.width + options.gap_x) / options.total_subrects_x;
    result.height = (result.height + options.gap_y) / options.total_subrects_y;
    result.x += result.width * x;
    result.y += result.height * y;
    result.width -= options.gap_x;
    result.height -= options.gap_y;
    return result;
}

const GridSubrectOptions = struct {
    total_subrects_x: usize,
    total_subrects_y: usize,
    padding: Padding,
    gap_x: f32,
    gap_y: f32,
};

const Padding = struct {
    top: f32,
    right: f32,
    bottom: f32,
    left: f32,

    fn all(all_: f32) Padding {
        return .{
            .top = all_,
            .right = all_,
            .bottom = all_,
            .left = all_,
        };
    }

    fn verticalHorizntal(vertical: f32, horizontal: f32) Padding {
        return .{
            .top = vertical,
            .right = horizontal,
            .bottom = vertical,
            .left = horizontal,
        };
    }

    fn topHorizntalBottom(top: f32, horizontal: f32, bottom: f32) Padding {
        return .{
            .top = top,
            .right = horizontal,
            .bottom = bottom,
            .left = horizontal,
        };
    }

    fn topRightBottomLeft(top: f32, right: f32, bottom: f32, left: f32) Padding {
        return .{
            .top = top,
            .right = right,
            .bottom = bottom,
            .left = left,
        };
    }

    fn subrect(self: Padding, rect: Rectangle) Rectangle {
        var result = rect;
        result.x += self.left;
        result.y += self.top;
        result.width -= self.left - self.right;
        result.height -= self.top - self.bottom;
        return result;
    }
};

fn screenRect() Rectangle {
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
