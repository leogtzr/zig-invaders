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

const Bullet = struct {
    position_x: f32,
    position_y: f32,
    width: f32,
    height: f32,
    speed: f32,
    active: bool,

    pub fn init(position_x: f32, position_y: f32, width: f32, height: f32) @This() {
        return .{
            .position_x = position_x,
            .position_y = position_y,
            .width = width,
            .height = height,
            .speed = 10.0,
            // Bullets start inactive.
            // Also: we set the speed at 10, so they should be faster than the player.
            .active = false,
        };
    }

    pub fn update(self: *@This()) void {
        if (self.active) {
            // Vamos hacia arriba ...
            self.position_y -= self.speed;
            if (self.position_y < 0) {
                self.active = false;
            }
        }
    }

    pub fn draw(self: @This()) void {
        if (self.active) {
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height), rl.Color.red);
        }
    }
};

const Invader = struct {
    position_x: f32,
    position_y: f32,
    width: f32,
    height: f32,
    speed: f32,
    alive: bool,

    pub fn init(position_x: f32, position_y: f32, width: f32, height: f32) @This() {
        return .{
            .position_x = position_x,
            .position_y = position_y,
            .width = width,
            .height = height,
            .speed = 5.0,
            .alive = true,
        };
    }

    pub fn draw(self: @This()) void {
        if (self.alive) {
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height), rl.Color.green);
        }
     }

};

pub fn main() void {
    const screenWidth: comptime_int = 800;
    const screenHeight: comptime_int = 600;
    const maxBullets = 10;
    const bulletWidth = 4.0;
    const bulletHeight = 10.0;
    const invaderCols = 11;
    const invaderRows = 5;
    const invaderWidth = 40.0;
    const invaderHeight = 30.0;
    const invaderStartX = 100.0;
    const invaderStartY = 50.0;
    const invaderSpacingX = 60.0;
    const invaderSpacingY = 40.0;


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

    var bullets: [maxBullets]Bullet = undefined;
    for (&bullets) |*bullet| {
        bullet.* = Bullet.init(0, 0, bulletWidth, bulletHeight);
    }

    var invaders: [invaderRows][invaderCols]Invader = undefined;

    for (&invaders, 0..) |*row, i| {
        for (row, 0..) |*invader, j| {
            const x = invaderStartX + @as(f32, @floatFromInt(j)) * invaderSpacingX;
            const y = invaderStartY + @as(f32, @floatFromInt(i)) * invaderSpacingY;
            invader.* = Invader.init(x, y, invaderWidth, invaderHeight);
        }
    }

    // 60 frames per second
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        // Since we know that when we begin drawing, we need to stop drawing, so we can use
        // defer here...
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        player.update();
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            for (&bullets) |*bullet| {
                if (!bullet.active) {
                    bullet.position_x = player.position_x + (player.width / 2) - (bullet.width / 2);
                    bullet.position_y = player.position_y;
                    bullet.active = true;

                    break;
                }
            }
        }

        // Update logic
        for (&bullets) |*bullet| {
            bullet.update();
        }

        player.draw();
        // Draw logic
        for (&bullets) |*bullet| {
            bullet.draw();
        }

        for (&invaders) |*row| {
            for (row) |*invader| {
                invader.draw();
            }
        }

        rl.drawText("Zig Invaders", 300, 250, 40, rl.Color.green);
    }
}
