package engine

import rl "vendor:raylib"
import "core:fmt"

Falling :: struct {
    velocity: Vector2,
    remainder: Vector2, // TODO: move to subpixel movement component?
    acceleration: Vector2,
    state: Falling_Block_State,
    riders: [dynamic]^Collider,
}

Falling_Block_State :: enum {
    Suspended,
    Falling,
    Landed
}

falling_block_update :: proc(scene: ^Scene, actor: Actor, block: ^Block, dt: f32) {
    block_collider := scene.colliders[actor]
    player_collider := scene.colliders[scene.player.actor]

    if colliders_intersect_when_offset(block_collider, player_collider, Vector2{0, -1}) {
        block.falling.state = .Falling

        // TODO: the following does not feel great
        /*append(&block.falling.riders, &scene.player.collider)
        for actor, &block in scene.blocks {
            if block.has_falling && &block != &block {
                append(&block.falling.riders, &block.collider)
            }
        }*/
    }

    if block.falling.state == .Falling {
        falling_block_update_velocity(block, dt)
        falling_block_update_position(scene, actor, block, dt)
    }
}

falling_block_update_velocity :: proc(block: ^Block, dt: f32) {
    block.falling.velocity = add(block.falling.velocity, scale(dt, block.falling.acceleration))
}

falling_block_update_position :: proc(scene: ^Scene, actor: Actor, block: ^Block, dt: f32) {
    subpixel_move(scene, actor, Block, block, &block.falling.velocity.y, &block.falling.remainder.y, falling_block_when_offsettempt_move_y, falling_block_move_y, falling_block_collide_y, dt)
}

falling_block_when_offsettempt_move_y :: proc(scene: ^Scene, actor: Actor, block: ^Block, offset: f32) -> bool {
    solid := falling_block_collision_with_solid_when_offset(scene, actor, block, Vector2{0, offset})

    if solid != nil {
        falling_block_collide_y(block)
        return false
    }

    return true
}

falling_block_collision_with_solid_when_offset :: proc(scene: ^Scene, actor: Actor, block: ^Block, offset: Vector2) -> ^Block {

    solid := collider_intersecting_solid_when_offset(scene, scene.colliders[actor], offset, block)
    if solid != nil {
        return solid
    }

    for other_actor, &other_block in scene.blocks {
        if other_block.type != .Jump_Through {
            continue
        }

        block_collider := scene.colliders[actor]
        other_block_collider := scene.colliders[other_actor]
        if !colliders_intersect_when_offset(block_collider, other_block_collider, Vector2{0,1}) {
            continue
        }

        if colliders_intersect(block_collider, other_block_collider) {
            continue
        }

        return &other_block
    }
    return nil
}

falling_block_collide_y :: proc(block: ^Block) {
    block.falling.velocity.y = 0
    block.falling.remainder.y = 0
}
        
falling_block_move_y :: proc(scene: ^Scene, actor: Actor, block: ^Block, offset: f32) {
    transform := &scene.transforms[actor]
    collider := &scene.colliders[actor]
    transform.position = add(transform.position, Vector2{0, offset})
    collider.collision_rectangle.offset = transform.position
}

falling_block_render :: proc(scene: ^Scene, actor: Actor, block: ^Block) {
    transform := scene.transforms[actor]
    collider := scene.colliders[actor]
    w, h := collider.collision_rectangle.size.x, collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{transform.position.x, transform.position.y}, rl.Vector2{w, h}, rl.BROWN)
}