package engine

import "core:fmt"
import rl "vendor:raylib"

TARGET_FPS : i32 = 60

GRAVITY : f32 : 0.6 * 3600

player : Player
blocks : [dynamic]Block
time_scale : f32 = 1

step_through : bool = false // true
should_update : bool = false

run :: proc() {

    rl.InitWindow(512, 288, "2D Platformer Engine")
    //rl.SetTargetFPS(TARGET_FPS)
    
    player_init(&player, position = Vector2{512-128, 10})

    block1 := Block{
        position = Vector2{512-128,128},
        size = Vector2{32,32}
    } 

    block2 := Block{
        position = Vector2{512-96,128},
        size = Vector2{32,32}
    }

    block3 := Block{
        position = Vector2{32,160},
        size = Vector2{64,32}
    }

    append(&blocks, block1, block2, block3)
    
    for x := 0; x < 512; x += 32 {
        block := Block{
            position = Vector2{f32(x), 256},
            size = Vector2{32, 32},
        }

        append(&blocks, block)
    }
    
    for y := 0; y < 288; y += 32 {
        left_block := Block{
            position = Vector2{0, f32(y)},
            size = Vector2{32, 32},
        }

        right_block := Block{
            position = Vector2{512 - 32, f32(y)},
            size = Vector2{32, 32},
        }

        append(&blocks, left_block, right_block)
    }

    jt1 := Block {
        position = Vector2{256, 224},
        size = Vector2{32, 32},
        type = .Jump_Through
    }

    jt2 := Block {
        position = Vector2{256, 224-32},
        size = Vector2{32, 32},
        type = .Jump_Through
    }
    
    jt3 := Block {
        position = Vector2{256+32, 224-32},
        size = Vector2{32, 32},
        type = .Jump_Through
    }

    append(&blocks, jt1, jt2, jt3)

    for &block in blocks {
        block_init(&block)
    }

    falling1 := Block {
        position = Vector2{512-128-32,128},
        size = Vector2{32,32}
    }

    falling_block_init(&falling1)

    append(&blocks, falling1)

    for !rl.WindowShouldClose() {
        update()
        render()
    }

    rl.CloseWindow()
}

update :: proc() {
    time_scale = 0.25 if input.ctrl else 1

    dt : f32 = rl.GetFrameTime() * time_scale//* 60
    update_input_state()

    if input.restart_pressed {
        restart()
    }

    if step_through {
        if input.ctrl_pressed {
            should_update = true
        }

        if should_update {
            for &block in blocks {
                if block.has_falling {
                    falling_block_update(&block, dt)
                }
            }
            player_update(&player, dt)
            should_update = false
        }
    } else {
        for &block in blocks {
            if block.has_falling {
                falling_block_update(&block, dt)
            }
        }
        player_update(&player, dt)
    }
}

restart :: proc() {
    player_init(&player, position = Vector2{512-128, 10})
}

render :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    player_render(&player)
    //collision_rectangle_render(&player.collision_rectangle)

    for &block in blocks {
        if block.type == .Jump_Through {
            jumpthrough_block_render(&block)
        } else {
            if block.has_falling {
                falling_block_render(&block)
            } else {
                block_render(&block)
            }
        }
        collision_rectangle_render(&block.collision_rectangle)
    }

    render_gui()

    rl.EndDrawing()
}

render_gui :: proc() {
    fps := rl.GetFPS()
    text := fmt.ctprint("\n",
                        "FPS ", fps, "\n",
                        "slowmo ", input.ctrl, "\n", 
                        "physics_state ", player.physics_state, "\n",
                        "action ", player.action, "\n",
                        //"velocity.x: ", player.velocity.x,
                        //"x: ", player.position.x,
                        //"ground: ", player.ground, "\n",
                        //"wall_right: ", player.wall_right, "\n",
                        //"wall_left: ", player.wall_left, "\n",
                        "jump buffer ", player.jump_buffer, "\n",
                        "coyote time ", player.coyote_time, "\n",
                        "drop buffer ", player.drop_buffer, "\n",
                        "wall hold ", player.wall_hold, "\n",
                        "air jumps ", player.air_jumps_remaining, " / ", player.air_jumps, "\n",
                        "vel y ", player.velocity.y, "\n",
                        )
    
    draw_text_outlined(text, 8, -10, 20, rl.WHITE, rl.BLACK, 2)
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