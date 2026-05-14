const std = @import("std");
const rl = @import("raylib");
const gui = @import("qw_gui");

pub fn main() !void {
    rl.initWindow(600, 400, "Buttons example");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var counter: u32 = 0;
    var processed_value: ?u32 = null;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();
        gui.updateGuiGlobals();

        rl.clearBackground(.ray_white);

        if (increment_button.draw(gui.screenRect().subrect(.{
            .x = .{ .left = 150 },
            .y = .{ .top = 150 },
            .width = .{ .amount = 100 },
            .height = .{ .amount = 60 },
        }))) {
            counter +|= 1;
        }
        if (decrement_button.drawWithOptions(gui.screenRect().subrect(.{
            .x = .{ .right = -150 },
            .y = .{ .top = 150 },
            .width = .{ .amount = 100 },
            .height = .{ .amount = 60 },
        }), decrement_button_options)) {
            counter -|= 1;
        }
        reset_button.draw(gui.screenRect().subrect(.{
            .x = .{ .left = 20 },
            .y = .{ .top = 20 },
            .width = .{ .amount = 100 },
            .height = .{ .amount = 60 },
        }), .{&counter});
        if (process_counter_button.draw(gui.screenRect().subrect(.{
            .x = .{ .left = 20 },
            .y = .{ .top = 100 },
            .width = .{ .amount = 100 },
            .height = .{ .amount = 60 },
        }), .{counter})) |value| {
            processed_value = value;
        }

        rl.drawText(rl.textFormat("%d", .{counter}), 295, 100, 20, .black);
        if (processed_value) |value| {
            rl.drawText(rl.textFormat("%d", .{value}), 40, 180, 20, .black);
        }
    }
}

fn resetCounter(counter: *u32) void {
    counter.* = 0;
}

fn processCounter(counter: u32) u32 {
    return if (counter % 2 == 0) counter / 2 else counter * 3 + 1;
}

const increment_button: gui.buttons.Button = .{
    .text = "Increment value",
    .id = "increment_button",
};

const decrement_button: gui.buttons.Button = .{
    .text = "Decrement value",
    .id = "decrement_button",
};

const decrement_button_options: gui.buttons.ButtonOptions = .{
    .hovered_colors = .colors(.light_red, .dark_red, .dark_red),
    .held_colors = .colors(.red, .darker_red, .dark_red),
};

const reset_button: gui.buttons.FnButton(@TypeOf(resetCounter)) = .{
    .text = "Reset value",
    .func = resetCounter,
    .id = "reset_button",
};

const process_counter_button: gui.buttons.FnButton(@TypeOf(processCounter)) = .{
    .text = "Process value",
    .func = processCounter,
    .id = "process_button",
};
