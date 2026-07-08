package engine

import rl "vendor:raylib"

jump_through_block_render :: proc(b: ^Block) {
    w, h := b.collider.collision_rectangle.size.x, b.collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.Fade(rl.BLUE, 0.25))
}

