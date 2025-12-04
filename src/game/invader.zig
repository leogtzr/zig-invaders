const Rectangle = @import("rectangle.zig").Rectangle;
const rl = @import("raylib");

pub const Invader = struct {
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

