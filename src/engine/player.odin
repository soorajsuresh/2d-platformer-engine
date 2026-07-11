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
	actor:                                  Actor,
	collider:                               Collider,
	transform:                              Transform,
	velocity:                               Vector2,
	remainder:                              Vector2, // TODO: better name?
	acceleration:                           Vector2,
	resistance:                             f32,
	deceleration:                           f32,
	ground:                                 ^Block,
	wall_right:                             ^Block,
	wall_left:                              ^Block,
	physics_state:                          Player_Physics_State,
	air_jumps:                              int,
	air_jumps_remaining:                    int,
	jump_buffer:                            f32,
	coyote_time:                            f32,
	drop_buffer:                            f32,
	excess_velocity_y:                      f32,
	wall_hold:                              f32,
	previous_action:                        Player_Action,
	action:                                 Player_Action,
	horizontal_movement_direction_intended: f32,
	horizontal_movement_direction_actual:   f32,
	horizontal_facing_direction:            f32,
	can_move_horizontally:                  bool,
}

JUMP_BUFFER: f32 = 0.05
COYOTE_TIME: f32 = 0.05
DROP_BUFFER: f32 = 0.05
jumpthroughs_to_ignore: [dynamic]^Block

START_HORIZONTAL_VELOCITY: f32 : 2 * 60
MAX_HORIZONTAL_SPEED: f32 : 8 * 60
GROUND_ACCELERATION: f32 : 0.4 * 3600
GROUND_DECELERATION: f32 : 1.2 * 3600
FRICTION: f32 : 0.6 * 3600
AIR_ACCELERATION: f32 : 0.3 * 3600
AIR_RESISTANCE: f32 : 0.15 * 3600
AIR_DECELERATION: f32 : 0.4 * 3600

JUMP_VELOCITY: f32 : -7 * 60
FLOAT_THRESHOLD: f32 : 2 * 60
CEILING_HANG_FACTOR: f32 : 0.5
DEFAULT_AIR_JUMPS: int : 0
AIR_JUMP_VELOCITY: f32 : -5 * 60
WALL_JUMP_UPWARD_VELOCITY: f32 : -6 * 60
WALL_JUMP_OUTWARD_VELOCITY: f32 : 2 * 60
WALL_HOLD: f32 : 1

player_init :: proc(player: ^Player) {
	player.velocity = Vector2{}
	player.remainder = Vector2{}
	player.acceleration = Vector2{}
	player.ground = nil
	player.wall_right = nil
	player.wall_left = nil
	player.physics_state = .None
	player.air_jumps = DEFAULT_AIR_JUMPS
	player.air_jumps_remaining = player.air_jumps
	player.jump_buffer = 0
	player.coyote_time = 0
	player.drop_buffer = 0
	player.excess_velocity_y = 0
	player.previous_action = .None
	player.action = .Falling
	player.horizontal_movement_direction_actual = 0
	player.horizontal_movement_direction_intended = 0
	player.horizontal_facing_direction = 1
	player.can_move_horizontally = true
}

player_update :: proc(scene: ^Scene, actor: Actor, player: ^Player, dt: f32) {
	player_update_collisions(scene, actor, player)
	player_update_physics(scene, player, dt)
	player_update_action(player)
	player_update_velocity(player, dt)
	player_update_position(scene, actor, player, dt)
}

player_update_collisions :: proc(scene: ^Scene, actor: Actor, player: ^Player) {
	player.ground = player_collision_with_solid_when_offset(scene, actor, player, Vector2{0, 1})
	if player.ground == nil {
		jumpthroughs := player_collision_with_jumpthrough_below(scene, player)
		if len(jumpthroughs) > 0 {
			player.ground = jumpthroughs[0]
			if player.drop_buffer > 0 {
				player.ground = nil
			}
		}
	}

	player.wall_right = player_collision_with_solid_when_offset(scene, actor, player, Vector2{1, 0})
	player.wall_left = player_collision_with_solid_when_offset(scene, actor, player, Vector2{-1, 0})
}

player_collision_with_solid_when_offset :: proc(
	scene: ^Scene,
	actor: Actor,
	player: ^Player,
	offset: Vector2,
) -> ^Block {
	return collider_intersecting_solid_when_offset(scene, player.collider, offset)
}

player_collision_with_jumpthrough_below :: proc(scene: ^Scene, player: ^Player) -> [dynamic]^Block {

	jumpthroughs: [dynamic]^Block

	for actor, &block in scene.blocks {
		if block.type != .Jump_Through {
			continue
		}

		if !colliders_intersect_when_offset(player.collider, block.collider, Vector2{0, 1}) {
			continue
		}

		if colliders_intersect(player.collider, block.collider) {
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

player_update_physics :: proc(scene: ^Scene, player: ^Player, dt: f32) {

	if player.ground != nil && player.velocity.y >= 0 {
		if player.physics_state != .On_Ground {
			player.physics_state = .On_Ground
			player_reset_ground_physics(player)
			player.air_jumps_remaining = player.air_jumps
			player.coyote_time = COYOTE_TIME
		}
	} else {
		if player.physics_state != .In_Air {
			player.physics_state = .In_Air
			player_reset_air_physics(scene, player)
		}
	}

	if player.physics_state == .On_Ground {
	} else if player.physics_state == .In_Air {
		player.jump_buffer = max(0, player.jump_buffer - dt)
		player.coyote_time = max(0, player.coyote_time - dt)
		player.drop_buffer = max(0, player.drop_buffer - dt)
		player.wall_hold = max(0, player.wall_hold - dt)
	}

	if input.down_pressed {
		player.drop_buffer = DROP_BUFFER
	}
}

player_reset_ground_physics :: proc(player: ^Player) {
	player.acceleration.x = GROUND_ACCELERATION
	player.resistance = FRICTION
	player.deceleration = GROUND_DECELERATION
}

player_reset_air_physics :: proc(scene: ^Scene, player: ^Player) {
	player.acceleration.x = AIR_ACCELERATION
	player.acceleration.y = GRAVITY
	player.resistance = AIR_RESISTANCE
	player.deceleration = AIR_DECELERATION
}

player_update_action :: proc(player: ^Player) {

	player.previous_action = player.action

	player.horizontal_movement_direction_actual = sign(player.velocity.x)
	player.horizontal_movement_direction_intended = 0
	if input.right {
		player.horizontal_movement_direction_intended += 1
	}
	if input.left {
		player.horizontal_movement_direction_intended -= 1
	}

	turn := false
	looking_in_direction_of_motion :=
		player.horizontal_facing_direction * player.horizontal_movement_direction_actual
	intending_to_move_forward :=
		player.horizontal_facing_direction * player.horizontal_movement_direction_intended
	if looking_in_direction_of_motion < 0 {
		turn = true
	} else if looking_in_direction_of_motion == 0 && intending_to_move_forward < 0 {
		turn = true
	}

	if turn {
		if player.action != .WallSliding && player.action != .WallSlidingLookingAway {
			player.horizontal_facing_direction *= -1
		}
		turn = false
	}

	moving_along_path_of_motion :=
		player.horizontal_movement_direction_intended * player.horizontal_movement_direction_actual

	if input.jump_pressed {
		player.jump_buffer = JUMP_BUFFER
	}

	// ground actions
	if player.physics_state == .On_Ground {
		if moving_along_path_of_motion > 0 {
			player.action = .Running
		} else if moving_along_path_of_motion < 0 {
			player.action = .HardBraking
		} else if player.velocity.x != 0 {
			player.action = .Braking
		} else {
			player.action = .Idle
		}

		if (player.horizontal_movement_direction_intended > 0 && player.wall_right != nil) ||
		   (player.horizontal_movement_direction_intended < 0 && player.wall_left != nil) {
			player.action = .Pushing
		}

		// jumping
		if player.jump_buffer > 0 && player.coyote_time > 0 {
			player.action = .Jumping
			player.jump_buffer = 0
			player.coyote_time = 0
		}

		// air actions
	} else {

		// prevent falling
		dont_fall: bit_set[Player_Action] = {.WallSliding, .WallSlidingLookingAway}

		// falling
		if player.velocity.y > 0 && player.action not_in dont_fall {
			player.action = .Falling
		}

		// wall sliding
		if (player.horizontal_movement_direction_intended > 0 && player.wall_right != nil) ||
		   (player.horizontal_movement_direction_intended < 0 && player.wall_left != nil) {
			if player.velocity.y >= 0 {
				if player.action != .WallSliding && player.action != .WallSlidingLookingAway {
					player.wall_hold = WALL_HOLD
				}
				player.action = .WallSliding
			}
		}

		if player.action == .WallSliding && intending_to_move_forward < 0 {
			player.action = .WallSlidingLookingAway
		}

		if player.action == .WallSlidingLookingAway && intending_to_move_forward > 0 {
			player.action = .WallSliding
		}

		// wall jumping
		if player.jump_buffer > 0 && (player.action == .WallSliding || player.action == .WallSlidingLookingAway) {
			if player.action == .WallSlidingLookingAway {
				player.action = .WallJumpingAway
				player.horizontal_facing_direction *= -1
			} else {
				player.action = .WallJumping
			}
		}

		// air jumping
		if player.jump_buffer > 0 && player.coyote_time == 0 && player.air_jumps_remaining > 0 {
			player.action = .Air_Jumping
			player.air_jumps_remaining -= 1
			player.jump_buffer = 0
		}
	}

	cant_move: bit_set[Player_Action] = {.WallSliding, .WallSlidingLookingAway}
	player.can_move_horizontally = player.action not_in cant_move
}

player_update_velocity :: proc(player: ^Player, dt: f32) {
	player_update_horizontal_velocity(player, dt)
	player_update_vertical_velocity(player, dt)
}

player_update_horizontal_velocity :: proc(player: ^Player, dt: f32) {

	if player.can_move_horizontally {
		vel := player.velocity.x
		if player.horizontal_movement_direction_intended == 1 {
			if vel == 0 {
				vel = START_HORIZONTAL_VELOCITY * dt
			} else if vel > 0 {
				vel += player.acceleration.x * dt
			} else {
				vel += player.deceleration * dt
			}
		} else if player.horizontal_movement_direction_intended == -1 {
			if vel == 0 {
				vel = -START_HORIZONTAL_VELOCITY * dt
			} else if vel < 0 {
				vel -= player.acceleration.x * dt
			} else {
				vel -= player.deceleration * dt
			}
		} else {
			if vel > 0 {
				vel = max(0, vel - player.resistance * dt)
			} else if vel < 0 {
				vel = min(vel + player.resistance * dt, 0)
			}
		}
		vel = clamp(vel, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)
		player.velocity.x = vel
	}
}

player_update_vertical_velocity :: proc(player: ^Player, dt: f32) {

	if player.previous_action != player.action {
		#partial switch player.action {
		case .Jumping:
			player.velocity.y = JUMP_VELOCITY
		case .Air_Jumping:
			player.velocity.y = AIR_JUMP_VELOCITY
		case .WallSliding:
			player.velocity.y = 0
			player.excess_velocity_y = 0
		case .WallJumpingAway:
			player.velocity.y = WALL_JUMP_UPWARD_VELOCITY
			player.velocity.x = WALL_JUMP_OUTWARD_VELOCITY * player.horizontal_movement_direction_intended
		case .WallJumping:
			player.velocity.y = WALL_JUMP_UPWARD_VELOCITY
		}
	}

	// gravity
	grav := player.acceleration.y

	if player.velocity.y < 0 && input.jump {
		grav = player.acceleration.y * 0.65
	} else if player.velocity.y > 0 && player.velocity.y < FLOAT_THRESHOLD {
		grav = player.acceleration.y * 0.8
	}

	// ceiling hold
	if player.excess_velocity_y < 0 {
		player.excess_velocity_y += grav * dt

		// let go
		if player.excess_velocity_y > 0 {
			player.velocity.y = player.excess_velocity_y
			player.excess_velocity_y = 0
		}
	} else {

		// wall hold
		wall_slide_mult: f32 = 1
		if player.wall_hold > 0 && (player.action == .WallSliding || player.action == .WallSlidingLookingAway) {
			wall_slide_mult = 0
		}

		player.velocity.y += grav * wall_slide_mult * dt
	}
}

player_update_position :: proc(scene: ^Scene, actor: Actor, player: ^Player, dt: f32) {
	subpixel_move(
		scene,
		actor,
		Player,
		player,
		&player.velocity.x,
		&player.remainder.x,
		player_when_offsettempt_move_x,
		player_move_x,
		player_collide_x,
		dt,
	)
	subpixel_move(
		scene,
		actor,
		Player,
		player,
		&player.velocity.y,
		&player.remainder.y,
		player_when_offsettempt_move_y,
		player_move_y,
		player_collide_y,
		dt,
	)
}

player_when_offsettempt_move_x :: proc(
	scene: ^Scene,
	actor: Actor,
	player: ^Player,
	offset: f32,
) -> bool {
	if player_collision_with_solid_when_offset(scene, actor, player, Vector2{offset, 0}) != nil {
		player_collide_x(player)
		return false
	}

	return true
}

player_when_offsettempt_move_y :: proc(
	scene: ^Scene,
	actor: Actor,
	player: ^Player,
	offset: f32,
) -> bool {
	solid := player_collision_with_solid_when_offset(scene, actor, player, Vector2{0, offset})

	if solid == nil && offset > 0 {
		jumpthroughs := player_collision_with_jumpthrough_below(scene, player)
		if len(jumpthroughs) > 0 {
			solid = jumpthroughs[0]
			if player.drop_buffer > 0 {
				append(&jumpthroughs_to_ignore, ..jumpthroughs[:])
				solid = nil
				player.drop_buffer = 0
			}
		}
	}

	if solid != nil {
		if player.velocity.y < 0 {
			player.excess_velocity_y = player.velocity.y * CEILING_HANG_FACTOR
		}
		player_collide_y(player)
		return false
	}

	return true
}

player_collide_x :: proc(player: ^Player) {
	player.velocity.x = 0
	player.remainder.x = 0
}

player_collide_y :: proc(player: ^Player) {
	player.velocity.y = 0
	player.remainder.y = 0
}

player_move_x :: proc(scene: ^Scene, actor: Actor, player: ^Player, offset: f32) {
	player_move(scene, actor, player, Vector2{offset, 0})
}

player_move_y :: proc(scene: ^Scene, actor: Actor, player: ^Player, offset: f32) {
	player_move(scene, actor, player, Vector2{0, offset})
}

player_move :: proc(scene: ^Scene, actor: Actor, player: ^Player, offset: Vector2) {

    transform := &scene.transforms[actor]

	transform.position = add(transform.position, offset)
	player.collider.collision_rectangle.offset = transform.position
}

player_render :: proc(scene: ^Scene, player: ^Player) {

	transform := scene.transforms[player.actor]

	rl.DrawRectangleV(
		rl.Vector2{transform.position.x, transform.position.y},
		rl.Vector2 {
			player.collider.collision_rectangle.size.x,
			player.collider.collision_rectangle.size.y,
		},
		rl.MAGENTA,
	)

	facing_direction_line_x := transform.position.x + 4
	if player.horizontal_facing_direction > 0 {
		facing_direction_line_x = transform.position.x + 28
	}

	rl.DrawLineV(
		rl.Vector2{facing_direction_line_x, transform.position.y},
		rl.Vector2{facing_direction_line_x, transform.position.y + 31},
		rl.YELLOW,
	)
}
