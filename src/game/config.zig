// To keep everything organized and avoid magic numbers ...
pub const GameConfig = struct {
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

