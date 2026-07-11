package engine

import rl "vendor:raylib"

Block_Type :: enum {
    Solid,
    Jump_Through,
}

Block :: struct {
    collider: Collider,
    type: Block_Type,
    falling: Falling, // TODO: I don't like that every block has these fields -> falling component
    has_falling: bool
}

block_render :: proc(scene: ^Scene, actor: Actor, block: ^Block) {
    transform := scene.transforms[actor]
    w, h := block.collider.collision_rectangle.size.x, block.collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{transform.position.x, transform.position.y}, rl.Vector2{w, h}, rl.BLUE)
}
