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

    pub fn getRect(self: @This()) Rectangle {
        return .{
            .x = self.position_x,
            .y = self.position_y,
            .width = self.width,
            .height = self.height,
        };
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

    pub fn update(self: *@This(), dx: f32, dy: f32) void {
        self.position_x += dx;
        self.position_y += dy;
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

const EnemyBullet = struct {
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
            .speed = 5.0,
            .active = false,
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

    pub fn update(self: *@This(), screen_height: i32) void {
        if (self.active) {
            self.position_y += self.speed;
            if (self.position_y > @as(f32, @floatFromInt(screen_height))) {
                self.active = false;
            }
        }
    }

    pub fn draw(self: @This()) void {
        if (self.active) {
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height), rl.Color.magenta);
        }
    }
};

const Shield = struct {
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

fn resetGame(
    player: *Player, 
    bullets: []Bullet,
    enemy_bullets: []EnemyBullet,
    shields: []Shield,
    invaders: anytype,                   // pushing inference to its limits ... might have some problems with the ZLS
    invader_direction: *f32,
    score: *i32,
    config: *const GameConfig,
) void {
    score.* = 0;
    player.* =  Player.init(
        @as(f32, @floatFromInt(config.screenWidth)) / 2 - config.playerWidth / 2,
        @as(f32, @floatFromInt(config.screenHeight)) - 60.0,
        config.playerWidth,
        config.playerHeight,
    );

    for (bullets) |*bullet| {
        bullet.active = false;
    }

    for (enemy_bullets) |*bullet| {
        bullet.active = false;
    }

    for (shields, 0..) |*shield, i| {
        const x = config.shieldStartX + @as(f32, @floatFromInt(i)) * config.shieldSpacing;
        shield.* = Shield.init(x, config.shieldStartY, config.shieldWidth, config.shieldHeight);
    }

    for (invaders, 0..) |*row, i| {
        for (row, 0..) |*invader, j| {
            const x = config.invaderStartX + @as(f32, @floatFromInt(j)) * config.invaderSpacingX;
            const y = config.invaderStartY + @as(f32, @floatFromInt(i)) * config.invaderSpacingY;
            invader.* = Invader.init(x, y, config.invaderWidht, config.invaderHeight);
            // invader.* 
        }
    }

    invader_direction.* = 1.0;
}

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
    const invaderSpeed = 5.0;
    const invaderMoveDelay = 30;
    const invaderDropDistance = 20.0;
    const maxEnemyBullets = 20;
    const enemyShootDelay = 60;
    const enemyShootChance = 5;
    var game_over: bool = false;
    var game_won: bool = false;

    var invader_direction: f32 = 1.0; // > 0 is right, < 0 is left
    var move_timer: i32 = 0;
    var enemy_shoot_timer: i32 = 0;
    var score: i32 = 0;
    const shieldCount = 4;
    const shieldWidth = 80.0;
    const shieldHeight = 60.0;
    const shieldStartX = 150;
    const shieldStartY = 450.0;
    const shieldSpacing = 150.0;
    const playerWidth: comptime_float = 50.0;
    const playerHeight: comptime_float = 30.0;
    const playerStartY = @as(f32, @floatFromInt(screenHeight)) - 60.0;

    const config = GameConfig{
        .screenWidth = screenWidth,
        .screenHeight = screenHeight,
        .playerWidth = playerWidth,
        .playerHeight = playerHeight,
        .bulletWidht = bulletWidth,
        .bulletHeight = bulletHeight,
        .shieldStartX = shieldStartX,
        .shieldStartY = shieldStartY,
        .shieldWidth = shieldWidth,
        .shieldHeight = shieldHeight,
        .shieldSpacing = shieldSpacing,
        .invaderStartX = invaderStartX,
        .invaderStartY = invaderStartY,
        .invaderWidht = invaderWidth,
        .invaderHeight = invaderHeight,
        .invaderSpacingX = invaderSpacingX,
        .invaderSpacingY = invaderSpacingY,
        .playerStartY = playerStartY,
    };

    rl.initWindow(screenWidth, screenHeight, "Zig Invaders");

    defer rl.closeWindow();

    var player: Player = Player.init(
        @as(f32, @floatFromInt(screenWidth)) / 2 - playerWidth / 2,
        playerStartY,
        playerWidth,
        playerHeight,
    );

    var shields: [shieldCount]Shield = undefined;
    for (&shields, 0..) |*shield, i| {
        const x = shieldStartX + @as(f32, @floatFromInt(i)) * shieldSpacing;
        shield.* = Shield.init(x, shieldStartY, shieldWidth, shieldHeight);
    }

    var bullets: [maxBullets]Bullet = undefined;
    for (&bullets) |*bullet| {
        bullet.* = Bullet.init(0, 0, bulletWidth, bulletHeight);
    }

    var enemy_bullets: [maxEnemyBullets]EnemyBullet = undefined;
    for (&enemy_bullets) |*bullet| {
        bullet.* = EnemyBullet.init(0, 0, bulletWidth, bulletHeight);
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
        
        if (game_over) {
            rl.drawText("GAME OVER", 270, 250, 40, rl.Color.red);
            const score_text = rl.textFormat("Final Score %d", .{score});
            rl.drawText(score_text, 285, 310, 30, rl.Color.white);
            
            rl.drawText("PRESS ENTER to play again or ESC to quit", 180, 360, 20, rl.Color.green);
            if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                game_over = false;
                resetGame(&player, &bullets, &enemy_bullets, &shields, &invaders, &invader_direction, &score, &config);
            }
            continue;
        }

        if (game_won) {
            rl.drawText("YOU WIN", 320, 250, 40, rl.Color.gold);
            const score_text = rl.textFormat("Final Score %d", .{score});
            rl.drawText(score_text, 280, 310, 30, rl.Color.white);
            
            rl.drawText("PRESS ENTER to play again or ESC to quit", 180, 360, 20, rl.Color.green);
            if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                game_won = false;
                resetGame(&player, &bullets, &enemy_bullets, &shields, &invaders, &invader_direction, &score, &config);
            }
            continue;
        }

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

        // Collision between the bullet and the invader.
        for (&bullets) |*bullet| {
            if (bullet.active) {
                for (&invaders) |*row| {
                    for (row) |*invader| {
                        if (invader.alive) {
                            if (bullet.getRect().intersects(invader.getRect())) {
                                invader.alive = false;
                                bullet.active = false;
                                score += 10;
                                break;
                            }
                        }
                    }
                }
                
                for (&shields) |*shield| {
                    if (shield.health > 0) {
                        if (bullet.getRect().intersects(shield.getRect())) {
                            bullet.active = false;
                            shield.health -= 1;
                            break;
                        }
                    }
                }
            }
        }

        for (&enemy_bullets) |*bullet| {
            bullet.update(screenHeight);
            if (bullet.active) {
                if (bullet.getRect().intersects(player.getRect())) {
                    bullet.active = false;
                    game_over = true;
                    // rl.drawText("GAME OVER", 20, 20, 20, rl.Color.red);
                }

                for (&shields) |*shield| {
                    if (shield.health > 0) {
                        if (bullet.getRect().intersects(shield.getRect())) {
                            bullet.active = false;
                            shield.health -= 1;
                            break;
                        }
                    }
                }

            }
        }
        enemy_shoot_timer += 1;
        if (enemy_shoot_timer >= enemyShootDelay) {
            enemy_shoot_timer = 0;
            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive and rl.getRandomValue(0, 100) < enemyShootChance) {
                        for (&enemy_bullets) |*bullet| {
                            if (!bullet.active) {
                                bullet.position_x = invader.position_x + invader.width / 2 - bullet.width / 2;
                                bullet.position_y = invader.position_y + invader.height;
                                bullet.active = true;
                                break;
                            }
                        }
                    }
                }
            }
        }

        move_timer += 1;
        if (move_timer >= invaderMoveDelay) {
            move_timer = 0;

            var hit_edge = false;

            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive) {
                        // Check the next_x ()
                        const next_x = invader.position_x + (invaderSpeed * invader_direction);
                        if ((next_x < 0) or (next_x + invader.width) > @as(f32, @floatFromInt(screenWidth))) {
                            hit_edge = true;
                            break;
                        }
                    }
                    // invader.update(invaderSpeed * invader_direction, 0);
                }
                if (hit_edge) {
                    break;
                }
            }
            if (hit_edge) {
                invader_direction *= -1.0;
                for (&invaders) |*row| {
                    for (row) |*invader| {
                        invader.update(0, invaderDropDistance);
                    }
                }
            } else {
                for (&invaders) |*row| {
                    for (row) |*invader| {
                        invader.update(invaderSpeed * invader_direction, 0);
                    }
                }
            }

            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive) {
                        if (invader.getRect().intersects(player.getRect())) {
                            game_won = false;
                            game_over = true;
                        }
                    }
                }
            }
        }
        

        var all_invaders_dead = true;
        all_dead_lbl:
        for (&invaders) |*row| {
            for (row) |*invader| {
                if (invader.alive) {
                    all_invaders_dead = false;
                    break :all_dead_lbl;
                }
            }
        }

        if (all_invaders_dead) {
            // we won:
            game_won = true;
        }

        // Draw logic:
        for (&shields) |*shield| {
            shield.draw();
        }
        player.draw();

        for (&bullets) |*bullet| {
            bullet.draw();
        }

        for (&invaders) |*row| {
            for (row) |*invader| {
                invader.draw();
            }
        }

        for (&enemy_bullets) |*bullet| {
            bullet.draw();
        }

        const score_text = rl.textFormat("Score: %d", .{score});
        rl.drawText(score_text, 20, screenHeight - 20, 20, rl.Color.white);
        rl.drawText("Zig Invaders", 300, 250, 30, rl.Color.green);
        rl.drawText("Zig Invaders - SPACE to shoot, ESC to quit", 20, 20, 20, rl.Color.green);
    }
}
