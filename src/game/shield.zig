const rl = @import("raylib");
const Rectangle = @import("rectangle.zig").Rectangle;

pub const Shield = struct {
    position_x: f32,
    position_y: f32,
    width: f32,
    height: f32,
    // The shields can take multiple hits before they disapear
    health: i32,

    pub fn init(position_x: f32, position_y: f32, width: f32, height: f32) @This() {
        return .{
            .position_x = position_x,
            .position_y = position_y,
            .width = width,
            .height = height,
            .health = 10,
        };
    }

    pub fn getRect(self: @This()) Rectangle {
        return .{
            .x = self.position_x,
            .y = self.position_y,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn draw(self: @This()) void {
        if (self.health > 0) {
            const alpha = @as(u8, @intCast(@min(255, self.health * 25)));
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height), rl.Color{
                .r = 0,
                .g = 255,
                .b = 255,
                .a = alpha,
            });
        }
    }
};


