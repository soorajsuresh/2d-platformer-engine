package engine

import "core:fmt"
import rl "vendor:raylib"

Block_Type :: enum {
    Solid,
    Jump_Through,
}

Block :: struct {
    position: Vector2,
    size: Vector2,
    collision_rectangle: CollisionRectangle,
    type: Block_Type,
    falling: Falling, // TODO: I dont like that every block has these fields
    has_falling: bool
}

Falling :: struct {
    velocity: Vector2,
    remainder: Vector2,
    acceleration: Vector2,
    state: Falling_Block_State,
}

Falling_Block_State :: enum {
    Suspended,
    Falling,
    Landed
}

block_init :: proc(b: ^Block) {
    b.collision_rectangle = CollisionRectangle{b.position, b.size}
    b.has_falling = false
}

falling_block_init :: proc(b: ^Block) {
    block_init(b)
    b.has_falling = true
    b.falling = Falling {
        acceleration = Vector2{0, GRAVITY},
        state = .Suspended
    }
}

falling_block_update :: proc(b: ^Block, dt: f32) {
    if intersects_at(b.collision_rectangle, player.collision_rectangle, Vector2{0, -1}) {
        b.falling.state = .Falling
    }

    if b.falling.state == .Falling {
        falling_block_update_velocity(b, dt)
        falling_block_update_position(b, dt)
    }
}

falling_block_update_velocity :: proc(b: ^Block, dt: f32) {
    b.falling.velocity = add(b.falling.velocity, scale(dt, b.falling.acceleration))
}

falling_block_update_position :: proc(b: ^Block, dt: f32) {
    subpixel_move(Block, b, &b.falling.velocity.y, &b.falling.remainder.y, falling_block_attempt_move_y, falling_block_move_y, falling_block_collide_y, dt)
}

falling_block_attempt_move_y :: proc(b: ^Block, offset: f32) -> bool {
    solid := falling_block_collision_with_solid_at(b, Vector2{0, offset})

    if solid != nil {
        falling_block_collide_y(b)
        return false
    }

    return true
}

falling_block_collision_with_solid_at :: proc(p: ^Block, offset: Vector2) -> ^Block {
    /*solid := intersecting_solid_at(p.collision_rectangle, offset)
    if solid == nil {
        for &block in blocks {
            if block.type != .Jump_Through {
                continue
            }

            if !intersects(rect, block.collision_rectangle) {
                continue
            }

            if intersects(p.collision_rectangle, block.collision_rectangle) {
                continue
            }

            return &block
        }
    }*/
    return nil
}

falling_block_collide_y :: proc(b: ^Block) {
    b.falling.velocity.y = 0
    b.falling.remainder.y = 0
}
        
falling_block_move_y :: proc(b: ^Block, offset: f32) {
    b.position = add(b.position, Vector2{0, offset})
    b.collision_rectangle.offset = b.position
}

block_render :: proc(b: ^Block) {
    w, h := b.collision_rectangle.size.x, b.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.BLUE)
}

jumpthrough_block_render :: proc(b: ^Block) {
    w, h := b.collision_rectangle.size.x, b.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.Fade(rl.BLUE, 0.25))
}

falling_block_render :: proc(b: ^Block) {
    w, h := b.collision_rectangle.size.x, b.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{b.position.x, b.position.y}, rl.Vector2{w, h}, rl.BROWN)
}