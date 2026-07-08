package engine

import rl "vendor:raylib"

Block_Type :: enum {
    Solid,
    Jump_Through,
}

Block :: struct {
    actor: Actor,
    collider: Collider,
    position: Vector2,
    size: Vector2,
    type: Block_Type,
    falling: Falling, // TODO: I don't like that every block has these fields -> falling component
    has_falling: bool
}

block_init :: proc(b: ^Block) {
    b.collider.collision_rectangle = CollisionRectangle{b.position, b.size}
    b.has_falling = false
}

block_render :: proc(b: ^Block) {
    w, h := b.collider.collision_rectangle.size.x, b.collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.BLUE)
}
