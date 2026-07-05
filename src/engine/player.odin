package engine

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Player_Physics_State :: enum {
    None,
    On_Ground,
    In_Air,
}

Player_Action :: enum {
    None,
    Idle,
    Running,
    Braking,
    HardBraking,
    Pushing,
    Jumping,
    Air_Jumping,
    Falling,
    WallSliding,
    WallSlidingLookingAway,
    WallJumpingAway,
    WallJumping,
}

Player :: struct {
    position: Vector2,
    velocity: Vector2,
    remainder: Vector2, // TODO: better name?
    acceleration: Vector2,
    resistance: f32,
    deceleration: f32,
    collision_rectangle: CollisionRectangle,
    ground: ^Block,
    wall_right: ^Block,
    wall_left: ^Block,
    physics_state: Player_Physics_State,
    air_jumps: int,
    air_jumps_remaining: int,
    jump_buffer: f32,
    coyote_time: f32,
    drop_buffer: f32,
    excess_velocity_y: f32,
    wall_hold: f32,
    previous_action: Player_Action,
    action: Player_Action,
    horizontal_movement_direction_intended: f32,
    horizontal_movement_direction_actual: f32,
    horizontal_facing_direction: f32,
    can_move_horizontally: bool,
}

JUMP_BUFFER: f32 = 0.05
COYOTE_TIME: f32 = 0.05
DROP_BUFFER: f32 = 0.05
jumpthroughs_to_ignore : [dynamic]^Block

START_HORIZONTAL_VELOCITY: f32 : 2 * 60
MAX_HORIZONTAL_SPEED : f32 : 8 * 60
GROUND_ACCELERATION : f32 : 0.4 * 3600
GROUND_DECELERATION : f32 : 1.2 * 3600
FRICTION : f32 : 0.6 * 3600
AIR_ACCELERATION : f32 : 0.3 * 3600
AIR_RESISTANCE : f32 : 0.15 * 3600
AIR_DECELERATION : f32 : 0.4 * 3600

JUMP_VELOCITY: f32 : -7 * 60
FLOAT_THRESHOLD: f32 : 2 * 60
CEILING_HANG_FACTOR: f32 : 0.5
DEFAULT_AIR_JUMPS: int : 0
AIR_JUMP_VELOCITY: f32 : -5 * 60
WALL_JUMP_UPWARD_VELOCITY: f32 : -6 * 60
WALL_JUMP_OUTWARD_VELOCITY: f32 : 2 * 60
WALL_HOLD: f32 : 1

player_init :: proc (p: ^Player, position: Vector2) {
    p.position = position
    p.velocity = Vector2{}
    p.remainder = Vector2{}
    p.acceleration = Vector2{}
    p.collision_rectangle = CollisionRectangle{p.position, Vector2{32, 32}}
    p.ground = nil
    p.wall_right = nil
    p.wall_left = nil
    p.physics_state = .None
    p.air_jumps = DEFAULT_AIR_JUMPS
    p.air_jumps_remaining = p.air_jumps    
    p.jump_buffer = 0
    p.coyote_time = 0
    p.drop_buffer = 0
    p.excess_velocity_y = 0
    p.previous_action = .None
    p.action = .Falling
    p.horizontal_movement_direction_actual = 0
    p.horizontal_movement_direction_intended = 0
    p.horizontal_facing_direction = 1
    p.can_move_horizontally = true
}

player_update :: proc(p: ^Player, dt: f32) {
    player_update_collisions(p)
    player_update_physics(p, dt)
    player_update_action(p)
    player_update_velocity(p, dt)
    player_update_position(p, dt)
}

player_update_collisions :: proc(p: ^Player) {
    p.ground = player_collision_with_solid_at(p, Vector2{0, 1})
    if p.ground == nil {
        jumpthroughs := player_collision_with_jumpthrough_below(p)
        if len(jumpthroughs) > 0 {
            p.ground = jumpthroughs[0]
            fmt.println("here 1")
            if p.drop_buffer > 0 {
                p.ground = nil
            fmt.println("here 2")
            }
        }
    }
    
    p.wall_right = player_collision_with_solid_at(p, Vector2{1, 0})
    p.wall_left = player_collision_with_solid_at(p, Vector2{-1, 0})
}

player_collision_with_solid_at :: proc(p: ^Player, offset: Vector2) -> ^Block {
    return intersecting_solid_at(p.collision_rectangle, offset)
}

player_collision_with_jumpthrough_below :: proc(p: ^Player) -> [dynamic]^Block { 

    jumpthroughs : [dynamic]^Block

    for &block in blocks {
        if block.type != .Jump_Through {
            continue
        }

        if !intersects_at(p.collision_rectangle, block.collision_rectangle, Vector2{0,1}) {
            continue
        }

        if intersects(p.collision_rectangle, block.collision_rectangle) {
            should_ignore, to_ignore_index := player_should_ignore(&block)
            if should_ignore {
                unordered_remove(&jumpthroughs_to_ignore, to_ignore_index)
            }
            continue
        }

        should_ignore, _ := player_should_ignore(&block)
        if should_ignore {
            continue
        }

        append(&jumpthroughs, &block)
    }

    return jumpthroughs 
}

player_should_ignore :: proc(jt: ^Block) -> (bool, int) {
    for to_ignore, i in jumpthroughs_to_ignore {
        if jt == to_ignore {
            return true, i
        }
    }
    return false, -1
}

player_update_physics :: proc(p: ^Player, dt: f32) {
    
    if p.ground != nil && p.velocity.y >= 0 {
        if p.physics_state != .On_Ground {
            p.physics_state = .On_Ground
            player_reset_ground_physics(p)
            p.air_jumps_remaining = p.air_jumps
            p.coyote_time = COYOTE_TIME
        }
    } else {
        if p.physics_state != .In_Air {
            p.physics_state = .In_Air
            player_reset_air_physics(p)
        }
    }

    if p.physics_state == .On_Ground {
    } else if p.physics_state == .In_Air {
        p.jump_buffer = max(0, p.jump_buffer - dt)
        p.coyote_time = max(0, p.coyote_time - dt)
        p.drop_buffer = max(0, p.drop_buffer - dt)
        p.wall_hold = max(0, p.wall_hold - dt)
    }

    if input.down_pressed {
        p.drop_buffer = DROP_BUFFER
    }
}

player_reset_ground_physics :: proc(p: ^Player) {
    p.acceleration.x = GROUND_ACCELERATION
    p.resistance = FRICTION
    p.deceleration = GROUND_DECELERATION
}

player_reset_air_physics :: proc(p: ^Player) {
    p.acceleration.x = AIR_ACCELERATION
    p.acceleration.y = GRAVITY
    p.resistance = AIR_RESISTANCE
    p.deceleration = AIR_DECELERATION
}

player_update_action :: proc(p: ^Player) {

    p.previous_action = p.action

    p.horizontal_movement_direction_actual = sign(p.velocity.x)
    p.horizontal_movement_direction_intended = 0
    if input.right { 
        p.horizontal_movement_direction_intended += 1 
    }
    if input.left { 
        p.horizontal_movement_direction_intended -= 1 
    }

    turn := false
    looking_in_direction_of_motion := p.horizontal_facing_direction * p.horizontal_movement_direction_actual
    intending_to_move_forward := p.horizontal_facing_direction * p.horizontal_movement_direction_intended
    if looking_in_direction_of_motion < 0 {
        turn = true
    } else if looking_in_direction_of_motion == 0 && intending_to_move_forward < 0 {
        turn = true
    }

    if turn {
        if p.action != .WallSliding && p.action != .WallSlidingLookingAway {
            p.horizontal_facing_direction *= -1
        }
        turn = false
    }

    moving_along_path_of_motion := p.horizontal_movement_direction_intended * p.horizontal_movement_direction_actual

    if input.jump_pressed {
        p.jump_buffer = JUMP_BUFFER
    }

    // ground actions
    if p.physics_state == .On_Ground {
        if moving_along_path_of_motion > 0 {
            p.action = .Running
        } else if moving_along_path_of_motion < 0 {
            p.action = .HardBraking
        } else if p.velocity.x != 0 {
            p.action = .Braking
        } else {
            p.action = .Idle
        }

        if (p.horizontal_movement_direction_intended > 0 && p.wall_right != nil) || (p.horizontal_movement_direction_intended < 0 && p.wall_left != nil) {
            p.action = .Pushing
        }

        // jumping
        if p.jump_buffer > 0 && p.coyote_time > 0 {
            p.action = .Jumping
            p.jump_buffer = 0
            p.coyote_time = 0
        }

    // air actions
    } else {

        // prevent falling
        dont_fall: bit_set[Player_Action] = {.WallSliding, .WallSlidingLookingAway}

        // falling
        if p.velocity.y > 0 && p.action not_in dont_fall {
            p.action = .Falling
        }

        // wall sliding
        if (p.horizontal_movement_direction_intended > 0 && p.wall_right != nil) || (p.horizontal_movement_direction_intended < 0 && p.wall_left != nil) {
            if p.velocity.y >= 0 {
                if p.action != .WallSliding && p.action != .WallSlidingLookingAway {
                    p.wall_hold = WALL_HOLD
                }
                p.action = .WallSliding
            }
        }

        if p.action == .WallSliding && intending_to_move_forward < 0 {
            p.action = .WallSlidingLookingAway
        }

        if p.action == .WallSlidingLookingAway && intending_to_move_forward > 0 {
            p.action = .WallSliding
        }

        // wall jumping
        if p.jump_buffer > 0 && (p.action == .WallSliding || p.action == .WallSlidingLookingAway) {
            if p.action == .WallSlidingLookingAway {
                p.action = .WallJumpingAway
                p.horizontal_facing_direction *= -1
            } else {
                p.action = .WallJumping
            }
        }

        // air jumping
        if p.jump_buffer > 0 && p.coyote_time == 0 && p.air_jumps_remaining > 0 {
            p.action = .Air_Jumping
            p.air_jumps_remaining -= 1
            p.jump_buffer = 0
        }
    }

    cant_move : bit_set[Player_Action] = {.WallSliding, .WallSlidingLookingAway}
    p.can_move_horizontally = p.action not_in cant_move
}

player_update_velocity :: proc(p: ^Player, dt: f32) {
    player_update_horizontal_velocity(p, dt)    
    player_update_vertical_velocity(p, dt)
}

player_update_horizontal_velocity :: proc(p: ^Player, dt: f32) {

    if p.can_move_horizontally {
        vel := p.velocity.x
        if p.horizontal_movement_direction_intended == 1 {
            if vel == 0 {
                vel = START_HORIZONTAL_VELOCITY * dt
            } else if vel > 0 {
                vel += p.acceleration.x * dt
            } else {
                vel += p.deceleration * dt
            }
        } else if p.horizontal_movement_direction_intended == -1 {
            if vel == 0 {
                vel = -START_HORIZONTAL_VELOCITY * dt
            } else if vel < 0 {
                vel -= p.acceleration.x * dt
            } else {
                vel -= p.deceleration * dt
            }
        } else {
            if vel > 0 {
                vel = max(0, vel - player.resistance * dt)
            } else if vel < 0 {
                vel = min(vel + player.resistance * dt, 0)
            }
        }
        vel = clamp(vel, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)
        p.velocity.x = vel
    }
}

player_update_vertical_velocity :: proc(p: ^Player, dt: f32) {

    if p.previous_action != p.action {
        #partial switch p.action {
            case .Jumping:
                p.velocity.y = JUMP_VELOCITY
            case .Air_Jumping:
                p.velocity.y = AIR_JUMP_VELOCITY
            case .WallSliding:
                p.velocity.y = 0
                p.excess_velocity_y = 0
            case .WallJumpingAway:
                p.velocity.y = WALL_JUMP_UPWARD_VELOCITY
                p.velocity.x = WALL_JUMP_OUTWARD_VELOCITY * p.horizontal_movement_direction_intended
            case .WallJumping:
                p.velocity.y = WALL_JUMP_UPWARD_VELOCITY
        }
    }

    // gravity
    grav := p.acceleration.y

    if p.velocity.y < 0 && input.jump {
        grav = p.acceleration.y * 0.65
    } else if p.velocity.y > 0 && p.velocity.y < FLOAT_THRESHOLD {
        grav = p.acceleration.y * 0.8
    }

    // ceiling hold
    if p.excess_velocity_y < 0 {
        p.excess_velocity_y += grav * dt

        // let go
        if p.excess_velocity_y > 0 {
            p.velocity.y = p.excess_velocity_y
            p.excess_velocity_y = 0
        }
    } else {

        // wall hold
        wall_slide_mult : f32 = 1
        if p.wall_hold > 0 && (p.action == .WallSliding || p.action == .WallSlidingLookingAway) {
            wall_slide_mult = 0
        }

        p.velocity.y += grav * wall_slide_mult * dt
    }
}

player_update_position :: proc(p: ^Player, dt: f32) {
    subpixel_move(Player, p, &p.velocity.x, &p.remainder.x, player_attempt_move_x, player_move_x, player_collide_x, dt)
    subpixel_move(Player, p, &p.velocity.y, &p.remainder.y, player_attempt_move_y, player_move_y, player_collide_y, dt)
}

player_attempt_move_x :: proc(p: ^Player, offset: f32) -> bool {
    if player_collision_with_solid_at(p, Vector2{offset, 0}) != nil {
        player_collide_x(p)
        return false
    }

    return true
}

player_attempt_move_y :: proc(p: ^Player, offset: f32) -> bool {
    solid := player_collision_with_solid_at(p, Vector2{0, offset})

    if solid == nil && offset > 0 {
        jumpthroughs := player_collision_with_jumpthrough_below(p)
        if len(jumpthroughs) > 0 {
            solid = jumpthroughs[0]
            if p.drop_buffer > 0 {
                append(&jumpthroughs_to_ignore, ..jumpthroughs[:])
                solid = nil
                p.drop_buffer = 0
            }
        }
    }

    if solid != nil {
        if p.velocity.y < 0 {
            p.excess_velocity_y = p.velocity.y * CEILING_HANG_FACTOR
        }
        player_collide_y(p)
        return false
    }

    return true
}

player_collide_x :: proc(p: ^Player) {
    p.velocity.x = 0
    p.remainder.x = 0
}

player_collide_y :: proc(p: ^Player) {
    p.velocity.y = 0
    p.remainder.y = 0
}
        
player_move_x :: proc(p: ^Player, offset: f32) {
    player_move(p, Vector2{offset, 0})
}

player_move_y :: proc(p: ^Player, offset: f32) {
    player_move(p, Vector2{0, offset})
}

player_move :: proc (p: ^Player, offset: Vector2) {
    p.position = add(p.position, offset)
    p.collision_rectangle.offset = p.position
}

player_render :: proc(p: ^Player) {
    w, h := p.collision_rectangle.size.x, p.collision_rectangle.size.y
    rl.DrawRectangleV(rl.Vector2{p.position.x, p.position.y}, rl.Vector2{w, h}, rl.MAGENTA)

    facing_direction_line_x := p.position.x + 4
    if p.horizontal_facing_direction > 0 {
        facing_direction_line_x = p.position.x + 28
    }

    rl.DrawLineV(rl.Vector2{facing_direction_line_x, p.position.y}, rl.Vector2{facing_direction_line_x, p.position.y + 31}, rl.YELLOW)
}