const rl = @import("raylib");
const std = @import("std");
const cfg = @import("game/config.zig");
const Player = @import("game/player.zig").Player;
const Bullet = @import("game/bullet.zig").Bullet;
const EnemyBullet = @import("game/enemy_bullet.zig").EnemyBullet;
const GameState = @import("game/game_state.zig").GameState;
const Invader = @import("game/invader.zig").Invader;
const Shield = @import("game/shield.zig").Shield;

const INVADER_GRID_ROWS = 5;
const INVADER_GRID_COLS = 11;

fn resetGame(
    player: *Player,
    bullets: []Bullet,
    enemy_bullets: []EnemyBullet,
    shields: []Shield,
    invaders: anytype, // pushing inference to its limits ... might have some problems with the ZLS
    gameState: *GameState,
    config: *const cfg.GameConfig,
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

fn initBullets(bullets: []Bullet, config: cfg.GameConfig) void {
    for (bullets) |*bullet| {
        bullet.* = Bullet.init(0, 0, config.bulletWidth, config.bulletHeight);
    }
}

fn initEnemyBullets(enemyBullets: []EnemyBullet, config: cfg.GameConfig) void {
    for (enemyBullets) |*bullet| {
        bullet.* = EnemyBullet.init(0, 0, config.bulletWidth, config.bulletHeight);
    }
}

fn initShields(shields: []Shield, config: cfg.GameConfig) void {
    for (shields, 0..) |*shield, i| {
        const x = config.shieldStartX + @as(f32, @floatFromInt(i)) * config.shieldSpacing;
        shield.* = Shield.init(x, config.shieldStartY, config.shieldWidth, config.shieldHeight);
    }
}

fn initInvaders(invaders: *[INVADER_GRID_ROWS][INVADER_GRID_COLS]Invader, config: cfg.GameConfig) void {
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

    const config = cfg.GameConfig{
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
