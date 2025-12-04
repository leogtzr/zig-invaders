const rl = @import("raylib");
const std = @import("std");

const INVADER_GRID_ROWS = 5;
const INVADER_GRID_COLS = 11;

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

    bulletWidth: f32,
    bulletHeight: f32,

    shieldStartX: f32,
    shieldStartY: f32,
    shieldWidth: f32,
    shieldHeight: f32,
    shieldSpacing: f32,

    invaderStartX: f32,
    invaderStartY: f32,
    invaderWidth: f32,
    invaderHeight: f32,
    invaderSpacingX: f32,
    invaderSpacingY: f32,
    shieldCount: i32,
    maxBullets: i32,
    maxEnemyBullets: i32,

    invaderGridRows: i32,
    invaderGridCols: i32,
    invaderMoveDelay: i32,

    invaderSpeed: f32,
    invaderDropDistance: f32,
    enemyShootDelay: i32,
    enemyShootChance: i32,
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

// REEMPLAZA tu struct Invader con este:
const Invader = struct {
    position_x: f32,
    position_y: f32,
    width: f32,
    height: f32,
    speed: f32,
    alive: bool,
    color: rl.Color,
    animation_frame: u8,

    pub fn init(position_x: f32, position_y: f32, width: f32, height: f32) @This() {
        // Colores aleatorios para variedad
        const colors = [_]rl.Color{
            rl.Color.green,
            rl.Color{ .r = 50, .g = 205, .b = 50, .a = 255 }, // LimeGreen
            rl.Color{ .r = 0, .g = 128, .b = 0, .a = 255 }, // Green (dark)
            rl.Color{ .r = 144, .g = 238, .b = 144, .a = 255 }, // LightGreen
            rl.Color{ .r = 124, .g = 252, .b = 0, .a = 255 }, // LawnGreen
        };

        const colors_len = colors.len;
        const random_idx = @as(usize, @intCast(rl.getRandomValue(0, @as(i32, @intCast(colors_len - 1)))));
        return .{
            .position_x = position_x,
            .position_y = position_y,
            .width = width,
            .height = height,
            .speed = 5.0,
            .alive = true,
            .color = colors[random_idx],
            .animation_frame = 0,
        };
    }

    pub fn updateAnimation(self: *@This()) void {
        // Cambiar frame de animación (simple)
        self.animation_frame = (self.animation_frame + 1) % 2;
    }

    pub fn draw(self: @This()) void {
        if (!self.alive) return;

        const center_x = self.position_x + self.width / 2;
        const center_y = self.position_y + self.height / 2;

        // Cuerpo principal - diferente forma según frame de animación
        if (self.animation_frame == 0) {
            // Forma 1: Alien clásico
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width), @intFromFloat(self.height * 0.7), self.color);

            // Cabeza
            rl.drawTriangle(rl.Vector2{ .x = self.position_x, .y = self.position_y + self.height * 0.7 }, rl.Vector2{ .x = center_x, .y = self.position_y }, rl.Vector2{ .x = self.position_x + self.width, .y = self.position_y + self.height * 0.7 }, self.color);
        } else {
            // Forma 2: Alternativa
            rl.drawRectangle(@intFromFloat(self.position_x + self.width * 0.2), @intFromFloat(self.position_y), @intFromFloat(self.width * 0.6), @intFromFloat(self.height), self.color);

            // Antenas
            rl.drawRectangle(@intFromFloat(self.position_x), @intFromFloat(self.position_y), @intFromFloat(self.width * 0.2), @intFromFloat(self.height * 0.3), self.color);
            rl.drawRectangle(@intFromFloat(self.position_x + self.width * 0.8), @intFromFloat(self.position_y), @intFromFloat(self.width * 0.2), @intFromFloat(self.height * 0.3), self.color);
        }

        // Ojos (siempre visibles)
        const eye_size_f32 = @max(3.0, self.width / 10);
        rl.drawCircle(@intFromFloat(center_x - self.width * 0.25), @intFromFloat(center_y), eye_size_f32, rl.Color.red);
        rl.drawCircle(@intFromFloat(center_x + self.width * 0.25), @intFromFloat(center_y), eye_size_f32, rl.Color.red);

        // Pupilas
        const pupil_size_f32 = eye_size_f32 / 2;
        rl.drawCircle(@intFromFloat(center_x - self.width * 0.25), @intFromFloat(center_y), pupil_size_f32 / 2, rl.Color.black);
        rl.drawCircle(@intFromFloat(center_x + self.width * 0.25), @intFromFloat(center_y), pupil_size_f32 / 2, rl.Color.black);

        // Boca/ventosa
        const mouth_size_f32 = self.width / 8;
        rl.drawCircle(@intFromFloat(center_x), @intFromFloat(center_y + self.height * 0.3), mouth_size_f32, rl.Color.dark_gray);
    }

    pub fn update(self: *@This(), dx: f32, dy: f32) void {
        self.position_x += dx;
        self.position_y += dy;
        // Actualizar animación al moverse
        if (dx != 0 or dy != 0) {
            self.updateAnimation();
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
    invaders: anytype, // pushing inference to its limits ... might have some problems with the ZLS
    gameState: *GameState,
    config: *const GameConfig,
) void {
    player.* = Player.init(
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
            invader.* = Invader.init(x, y, config.invaderWidth, config.invaderHeight);
        }
    }

    gameState.invaderDirection = 1.0;
    gameState.moveTimer = 1;
    gameState.enemyShootTimer = 0;
    gameState.score = 0;
}

const GameState = struct {
    gameOver: bool,
    gameWon: bool,
    invaderDirection: f32,
    moveTimer: i32,
    enemyShootTimer: i32,
    score: i32,
};

fn initBullets(bullets: []Bullet, config: GameConfig) void {
    for (bullets) |*bullet| {
        bullet.* = Bullet.init(0, 0, config.bulletWidth, config.bulletHeight);
    }
}

fn initEnemyBullets(enemyBullets: []EnemyBullet, config: GameConfig) void {
    for (enemyBullets) |*bullet| {
        bullet.* = EnemyBullet.init(0, 0, config.bulletWidth, config.bulletHeight);
    }
}

fn initShields(shields: []Shield, config: GameConfig) void {
    for (shields, 0..) |*shield, i| {
        const x = config.shieldStartX + @as(f32, @floatFromInt(i)) * config.shieldSpacing;
        shield.* = Shield.init(x, config.shieldStartY, config.shieldWidth, config.shieldHeight);
    }
}

fn initInvaders(invaders: *[INVADER_GRID_ROWS][INVADER_GRID_COLS]Invader, config: GameConfig) void {
    for (0..INVADER_GRID_ROWS) |i| {
        for (0..INVADER_GRID_COLS) |j| {
            const x = config.invaderStartX + @as(f32, @floatFromInt(j)) * config.invaderSpacingX;
            const y = config.invaderStartY + @as(f32, @floatFromInt(i)) * config.invaderSpacingY;
            invaders[i][j] = Invader.init(x, y, config.invaderWidth, config.invaderHeight);
        }
    }
}

fn checkIfAllInvadersAreDead(invaders: *[INVADER_GRID_ROWS][INVADER_GRID_COLS]Invader) bool {
    var all_invaders_dead = true;
    all_dead_lbl: for (0..INVADER_GRID_ROWS) |i| {
        for (0..INVADER_GRID_COLS) |j| {
            if (invaders[i][j].alive) {
                all_invaders_dead = false;
                break :all_dead_lbl;
            }
        }
    }

    return all_invaders_dead;
}

pub fn main() void {
    var gameState = GameState{
        .gameOver = false,
        .gameWon = false,
        .invaderDirection = 1.0,
        .moveTimer = 0,
        .enemyShootTimer = 0,
        .score = 0,
    };

    const config = GameConfig{
        .screenWidth = 800,
        .screenHeight = 600,
        .playerWidth = 50.0,
        .playerHeight = 30.0,
        .bulletWidth = 4.0,
        .bulletHeight = 10.0,
        .shieldStartX = 150.0,
        .shieldStartY = 450.0,
        .shieldWidth = 80.0,
        .shieldHeight = 60.0,
        .shieldSpacing = 150.0,
        .invaderStartX = 100.0,
        .invaderStartY = 50.0,
        .invaderWidth = 40.0,
        .invaderHeight = 30.0,
        .invaderSpacingX = 60.0,
        .invaderSpacingY = 40.0,
        .playerStartY = @as(f32, @floatFromInt(600)) - 60,
        .shieldCount = 4,
        .maxBullets = 10,
        .maxEnemyBullets = 20,
        .invaderGridRows = 5,
        .invaderGridCols = 11,
        .invaderMoveDelay = 30.0,
        .invaderSpeed = 5.0,
        .invaderDropDistance = 20.0,
        .enemyShootDelay = 60,
        .enemyShootChance = 5,
    };

    rl.initWindow(config.screenWidth, config.screenHeight, "Zig Invaders");

    defer rl.closeWindow();

    var player: Player = Player.init(
        @as(f32, @floatFromInt(config.screenWidth)) / 2 - config.playerWidth / 2,
        config.playerStartY,
        config.playerWidth,
        config.playerHeight,
    );

    var shields: [config.shieldCount]Shield = undefined;
    initShields(&shields, config);

    var bullets: [config.maxBullets]Bullet = undefined;
    initBullets(&bullets, config);

    var enemy_bullets: [config.maxEnemyBullets]EnemyBullet = undefined;
    initEnemyBullets(&enemy_bullets, config);

    var invaders: [config.invaderGridRows][config.invaderGridCols]Invader = undefined;
    initInvaders(&invaders, config);

    // 60 frames per second
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        // Since we know that when we begin drawing, we need to stop drawing, so we can use
        // defer here...
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        if (gameState.gameOver) {
            rl.drawText("GAME OVER", 270, 250, 40, rl.Color.red);
            const score_text = rl.textFormat("Final Score %d", .{gameState.score});
            rl.drawText(score_text, 285, 310, 30, rl.Color.white);

            rl.drawText("PRESS ENTER to play again or ESC to quit", 180, 360, 20, rl.Color.green);
            if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                gameState.gameOver = false;
                resetGame(&player, &bullets, &enemy_bullets, &shields, &invaders, &gameState, &config);
            }
            continue;
        }

        if (gameState.gameWon) {
            rl.drawText("YOU WIN", 320, 250, 40, rl.Color.gold);
            const score_text = rl.textFormat("Final Score %d", .{gameState.score});
            rl.drawText(score_text, 280, 310, 30, rl.Color.white);

            rl.drawText("PRESS ENTER to play again or ESC to quit", 180, 360, 20, rl.Color.green);
            if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                gameState.gameWon = false;
                resetGame(&player, &bullets, &enemy_bullets, &shields, &invaders, &gameState, &config);
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
                                gameState.score += 10;
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
            bullet.update(config.screenHeight);
            if (bullet.active) {
                if (bullet.getRect().intersects(player.getRect())) {
                    bullet.active = false;
                    gameState.gameOver = true;
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

        gameState.enemyShootTimer += 1;
        if (gameState.enemyShootTimer >= config.enemyShootDelay) {
            gameState.enemyShootTimer = 0;
            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive and rl.getRandomValue(0, 100) < config.enemyShootChance) {
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

        gameState.moveTimer += 1;
        if (gameState.moveTimer >= config.invaderMoveDelay) {
            gameState.moveTimer = 0;

            var hit_edge = false;

            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive) {
                        const next_x = invader.position_x + (config.invaderSpeed * gameState.invaderDirection);
                        if ((next_x < 0) or (next_x + invader.width) > @as(f32, @floatFromInt(config.screenWidth))) {
                            hit_edge = true;
                            break;
                        }
                    }
                }
                if (hit_edge) {
                    break;
                }
            }
            if (hit_edge) {
                gameState.invaderDirection *= -1.0;
                for (&invaders) |*row| {
                    for (row) |*invader| {
                        invader.update(0, config.invaderDropDistance);
                    }
                }
            } else {
                for (&invaders) |*row| {
                    for (row) |*invader| {
                        invader.update(config.invaderSpeed * gameState.invaderDirection, 0);
                    }
                }
            }

            for (&invaders) |*row| {
                for (row) |*invader| {
                    if (invader.alive) {
                        if (invader.getRect().intersects(player.getRect())) {
                            gameState.gameWon = false;
                            gameState.gameOver = true;
                        }
                    }
                }
            }
        }

        gameState.gameWon = checkIfAllInvadersAreDead(&invaders);

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

        const score_text = rl.textFormat("Score: %d", .{gameState.score});
        rl.drawText(score_text, 20, config.screenHeight - 20, 20, rl.Color.white);
        rl.drawText("Zig Invaders", 300, 250, 30, rl.Color.green);
        rl.drawText("Zig Invaders - SPACE to shoot, ESC to quit", 20, 20, 20, rl.Color.green);
    }
}
