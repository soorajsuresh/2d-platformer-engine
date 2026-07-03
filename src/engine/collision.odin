package engine
import rl "vendor:raylib"

CollisionRectangle :: struct {
    offset: Vector2,
    size: Vector2
}

intersects :: proc(a, b: CollisionRectangle) -> bool {
    return a.offset.x < b.offset.x + b.size.x &&
           a.offset.x + a.size.x > b.offset.x &&
           a.offset.y < b.offset.y + b.size.y &&
           a.offset.y + a.size.y > b.offset.y
}

intersects_at :: proc(a, b: CollisionRectangle, offset: Vector2) -> bool {
    r := a
    r.offset = add(r.offset, offset)
    return intersects(r, b)
}

intersecting_solid :: proc(a: CollisionRectangle) -> ^Block {
    for &block in blocks {
        if intersects(a, block.collision_rectangle) && block.type == .Solid {
            return &block
        }
    }
    return nil
}

intersecting_solid_at :: proc(a: CollisionRectangle, offset: Vector2) -> ^Block {
    rect := a
    rect.offset = add(rect.offset, offset)
    return intersecting_solid(rect)
}

collision_rectangle_render :: proc(r: ^CollisionRectangle) {
    rect := rl.Rectangle{r.offset.x, r.offset.y, r.size.x, r.size.y}
    rl.DrawRectangleLinesEx(rect, 1, rl.Fade(rl.YELLOW, 0.5))
}