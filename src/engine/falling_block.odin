package engine

import rl "vendor:raylib"

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

falling_block_init :: proc(b: ^Block) {
    block_init(b)
    b.has_falling = true
    b.falling = Falling {
        acceleration = Vector2{0, GRAVITY},
        state = .Suspended
    }
}

falling_block_update :: proc(scene: ^Scene, b: ^Block, dt: f32) {

    if colliders_intersect_at(b.collider, scene.player.collider, Vector2{0, -1}) {
        b.falling.state = .Falling

        // TODO: the following does not feel great
        append(&b.falling.riders, &scene.player.collider)
        for actor, &block in scene.blocks {
            if block.has_falling && &block != b{
                append(&b.falling.riders, &block.collider)
            }
        }
    }

    if b.falling.state == .Falling {
        falling_block_update_velocity(b, dt)
        falling_block_update_position(scene, b, dt)
    }
}

falling_block_update_velocity :: proc(b: ^Block, dt: f32) {
    b.falling.velocity = add(b.falling.velocity, scale(dt, b.falling.acceleration))
}

falling_block_update_position :: proc(scene: ^Scene, b: ^Block, dt: f32) {
    subpixel_move(scene, Block, b, &b.falling.velocity.y, &b.falling.remainder.y, falling_block_attempt_move_y, falling_block_move_y, falling_block_collide_y, dt)
}

falling_block_attempt_move_y :: proc(scene: ^Scene, b: ^Block, offset: f32) -> bool {
    solid := falling_block_collision_with_solid_at(scene, b, Vector2{0, offset})

    if solid != nil {
        falling_block_collide_y(b)
        return false
    }

    return true
}

falling_block_collision_with_solid_at :: proc(scene: ^Scene, b: ^Block, offset: Vector2) -> ^Block {

    solid := collider_intersecting_solid_at(scene, b.collider, offset, b)
    if solid != nil {
        return solid
    }

    for actor, &block in scene.blocks {
        if block.type != .Jump_Through {
            continue
        }

        if !colliders_intersect_at(b.collider, block.collider, Vector2{0,1}) {
            continue
        }

        if colliders_intersect(b.collider, block.collider) {
            continue
        }

        return &block
    }
    return nil
}

falling_block_collide_y :: proc(b: ^Block) {
    b.falling.velocity.y = 0
    b.falling.remainder.y = 0
}
        
falling_block_move_y :: proc(b: ^Block, offset: f32) {
    b.position = add(b.position, Vector2{0, offset})
    b.collider.collision_rectangle.offset = b.position
}

falling_block_render :: proc(b: ^Block) {
    w, h := b.collider.collision_rectangle.size.x, b.collider.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.BROWN)
}