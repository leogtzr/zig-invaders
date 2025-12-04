const rl = @import("raylib");
const Rectangle = @import("rectangle.zig").Rectangle;

pub const Player = struct {
    position_x: f32,
    position_y: f32,
    width: f32,
    height: f32,
    speed: f32,

    pub fn init(position_x: f32, position_y: f32, width: f32, height: f32) @This() {
        // Using the anonymous init pattern:
        return .{
            .position_x = position_x,
            .position_y = position_y,
            .width = width,
            .height = height,
            // ToDo: read the speed from the GameConfig
            .speed = 5.0,
        };
    }

    // Need *This() because we are modifying
    pub fn update(self: *@This()) void {
        if (rl.isKeyDown(rl.KeyboardKey.right)) {
            // If we move to the right ...
            self.position_x += self.speed;
        }

        if (rl.isKeyDown(rl.KeyboardKey.left)) {
            // If we move to the right ...
            self.position_x -= self.speed;
        }
        if (self.position_x < 0) {
            self.position_x = 0;
        }
        if (self.position_x + self.width > @as(f32, @floatFromInt(rl.getScreenWidth()))) {
            self.position_x = @as(f32, @floatFromInt(rl.getScreenWidth())) - self.width;
        }
    }

    // Just reading:
    pub fn draw(self: @This()) void {
        rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height), rl.Color.blue);
    }

    pub fn getRect(self: @This()) Rectangle {
        return .{
            .x = self.position_x,
            .y = self.position_y,
            .width = self.width,
            .height = self.height,
        };
    }
};

