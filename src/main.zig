const rl = @import("raylib");
const Rectangle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    // Mechanics about colisions
    // By convention, the first parameter is self or this, the frst param is the type where we belong to.
    // Usage: rectangle.intersects(rectangle2)
    //
    // If we do not order the parameters like this, we would have to do something like this:
    // Rectangle.intersects(rect1, rect2)
    pub fn intersects(self: Rectangle, other: Rectangle) bool {
        return self.x < (other.x + other.width) and
            (self.x + self.width) > other.x and
            self.y < (other.y + other.height) and
            (self.y + self.height) > other.y;
    }
};

// To keep everything organized and avoid magic numbers ...
const GameConfig = struct {
    screenWidth: i32,
    screenHeight: i32,

    playerWidth: f32,
    playerHeight: f32,
    playerStartY: f32,

    bulletWidht: f32,
    bulletHeight: f32,

    shieldStartX: f32,
    shieldStartY: f32,
    shieldWidth: f32,
    shieldHeight: f32,
    shieldSpacing: f32,

    invaderStartX: f32,
    invaderStartY: f32,
    invaderWidht: f32,
    invaderHeight: f32,
    invaderSpacingX: f32,
    invaderSpacingY: f32,
};

const Player = struct {
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

pub fn main() void {
    const screenWidth: comptime_int = 800;
    const screenHeight: comptime_int = 600;

    rl.initWindow(screenWidth, screenHeight, "Zig Invaders");

    defer rl.closeWindow();

    const playerWidth: comptime_float = 50.0;
    const playerHeight: comptime_float = 30.0;

    var player: Player = Player.init(
        @as(f32, @floatFromInt(screenWidth)) / 2 - playerWidth / 2,
        @as(f32, @floatFromInt(screenHeight)) - 60.0,
        playerWidth,
        playerHeight,
    );

    // 60 frames per second
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        // Since we know that when we begin drawing, we need to stop drawing, so we can use
        // defer here...
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        player.update();
        player.draw();

        rl.drawText("Zig Invaders", 300, 250, 40, rl.Color.green);
    }
}
