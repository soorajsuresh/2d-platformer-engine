package engine

import "core:fmt"
import rl "vendor:raylib"

TARGET_FPS : i32 = 60
GRAVITY : f32 = 0.6 * 3600
DEBUG : bool = true

Engine :: struct {
    step_through : bool,
    should_update : bool,
    time_scale : f32,
}

Actor :: distinct u32

Scene :: struct {
    actors : [dynamic]Actor,
    next_actor: Actor,

    player : Player,
    blocks : map[Actor]Block,
}

create_actor :: proc(scene: ^Scene) -> Actor {
    actor := scene.next_actor
    scene.next_actor += 1
    append(&scene.actors, actor)
    return actor
}

player_create :: proc(scene: ^Scene) -> Actor {
    actor := create_actor(scene)
    player : Player
    player.actor = actor
    player_init(&player, position = Vector2{512-128, 10})
    player_add(scene, actor, player)
    return actor
}

player_add :: proc(scene: ^Scene, actor: Actor, player: Player) {
    scene.player = player
}

player_get :: proc(scene: ^Scene) -> ^Player {
    return &scene.player
}

block_create :: proc(scene: ^Scene, position: Vector2, size: Vector2, type: Block_Type = .Solid, falling: bool = false) -> Actor {
    actor := create_actor(scene)
    block := Block {
        actor = actor,
        position = position,
        size = size,
        type = type
    }
    if !falling {
        block_init(&block)
    } else {
        falling_block_init(&block)
    }
    block_add(scene, actor, block)
    return actor
}

jump_through_block_create :: proc(scene: ^Scene, position, size: Vector2) -> Actor {
    return block_create(scene, position, size, .Jump_Through)
}

falling_block_create :: proc(scene: ^Scene, position, size: Vector2) -> Actor {
    return block_create(scene, position, size, .Solid, falling = true)
}

block_add :: proc(scene: ^Scene, actor: Actor, block: Block) {
    scene.blocks[actor] = block
}

engine_init :: proc(engine: ^Engine) {
    engine.step_through = false
    engine.should_update = false
    engine.time_scale = 1
}

scene_init :: proc(scene: ^Scene) {
    
    player_create(scene)

    block_create(scene, Vector2{512-128,128}, Vector2{32,32})

    block_create(scene, Vector2{512-128,128}, Vector2{32,32})
    block_create(scene, Vector2{512-96,128}, Vector2{32,32})
    block_create(scene, Vector2{32,160}, Vector2{64,32})
    
    for x := 0; x < 512; x += 32 {
        block_create(scene, Vector2{f32(x), 256}, Vector2{32, 32})
    }
    
    for y := 0; y < 288; y += 32 {
        block_create(scene, Vector2{0, f32(y)}, size = Vector2{32, 32})
        block_create(scene, Vector2{512 - 32, f32(y)}, size = Vector2{32, 32})
    }

    jump_through_block_create(scene, Vector2{256, 224}, size = Vector2{32, 32})
    jump_through_block_create(scene, Vector2{256, 224-32},size = Vector2{32, 32})
    jump_through_block_create(scene, Vector2{256+32, 224-32},size = Vector2{32, 32})
    jump_through_block_create(scene, Vector2{256+64, 224-32},size = Vector2{32, 32})
    jump_through_block_create(scene, Vector2{256+96, 224-32},size = Vector2{32, 32})

    falling_block_create(scene, Vector2{512-128-32,128}, Vector2{32, 32})
}



run :: proc() {
    engine : Engine
    engine_init(&engine)

    scene : Scene
    scene_init(&scene)

    rl.InitWindow(512, 288, "2D Platformer Engine")
    rl.SetTargetFPS(TARGET_FPS)

    for !rl.WindowShouldClose() {
        update(&engine, &scene)
        render(&scene)
    }

    rl.CloseWindow()
}

update :: proc(engine: ^Engine, scene: ^Scene) {
    engine.time_scale = 0.25 if input.ctrl else 1

    dt : f32 = rl.GetFrameTime() * engine.time_scale
    update_input_state()

    if input.restart_pressed {
        scene_restart(scene)
    }

    if engine.step_through {
        if input.ctrl_pressed {
            engine.should_update = true
        }

        if engine.should_update {

            scene_update(scene, dt)
            
            engine.should_update = false
        }
    } else {
        scene_update(scene, dt)
    }
}

scene_update :: proc(scene: ^Scene, dt: f32) {
    for actor, &block in scene.blocks {
        if block.has_falling {
            falling_block_update(scene, &block, dt)
        }
    }
    player_update(scene, &scene.player, dt)
}

scene_restart :: proc(scene: ^Scene) {
    scene_end(scene)
    scene_init(scene)
}

scene_end :: proc(scene: ^Scene) {
    clear(&scene.actors)
    clear(&scene.blocks)
}

render :: proc(scene: ^Scene) {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    scene_render(scene)
    
    if DEBUG {
        debug_render(scene)
    }

    rl.EndDrawing()
}

scene_render :: proc(scene: ^Scene) {
    player_render(&scene.player)

    for actor, &block in scene.blocks {
        if block.type == .Jump_Through {
            jumpthrough_block_render(&block)
        } else {
            if block.has_falling {
                falling_block_render(&block)
            } else {
                block_render(&block)
            }
        }
    }
}

debug_render :: proc(scene : ^Scene) {
    
    player := &scene.player

    collision_rectangle_render(&player.collider.collision_rectangle)
    for actor, &block in scene.blocks {
        collision_rectangle_render(&block.collider.collision_rectangle)
    }
    
    text := fmt.ctprint("\n",
                        "FPS ", rl.GetFPS(), "\n",
                        "slowmo ", input.ctrl, "\n", 
                        "physics_state ", player.physics_state, "\n",
                        "action ", player.action, "\n",
                        "ground: ", player.ground, "\n",
                        "wall_right: ", player.wall_right, "\n",
                        "wall_left: ", player.wall_left, "\n",
                        "jump buffer ", player.jump_buffer, "\n",
                        "coyote time ", player.coyote_time, "\n",
                        "drop buffer ", player.drop_buffer, "\n",
                        "wall hold ", player.wall_hold, "\n",
                        "air jumps ", player.air_jumps_remaining, " / ", player.air_jumps, "\n",
                        "velocity.x: ", player.velocity.x, "\n",
                        "velocity.y ", player.velocity.y, "\n",
                        )
    
    draw_text_outlined(text, 8, -5, 10, rl.WHITE, rl.BLACK, 1)
}

draw_text_outlined :: proc(text: cstring, x, y: i32, font_size: i32, text_color: rl.Color, outline_color: rl.Color, outline_size: i32 = 1) {
    for y_off := -outline_size; y_off <= outline_size; y_off += 1 {
        for x_off := -outline_size; x_off <= outline_size; x_off += 1 {
            if x_off == 0 && y_off == 0 {
                continue
            }

            rl.DrawText(text, x + x_off, y + y_off, font_size, outline_color)
        }
    }

    rl.DrawText(text, x, y, font_size, text_color)
}