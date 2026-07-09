package engine

import rl "vendor:raylib"

jump_through_block_render :: proc(scene: ^Scene, actor: Actor, block: ^Block) {
    transform := scene.transforms[actor]
    w, h := block.collider.collision_rectangle.size.x, block.collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{transform.position.x, transform.position.y}, rl.Vector2{w, h}, rl.Fade(rl.BLUE, 0.25))
}

