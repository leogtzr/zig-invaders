pub const Rectangle = struct {
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

