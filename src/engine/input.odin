package engine

import rl "vendor:raylib"

Input :: struct {
    right: bool,
    left: bool,
    down_pressed: bool,
    jump: bool,
    jump_pressed: bool,
    ctrl: bool,
    ctrl_pressed: bool,
    restart_pressed: bool,
}

input: Input

update_input_state :: proc() {

    input.right = rl.IsKeyDown(.RIGHT)
    input.left = rl.IsKeyDown(.LEFT)

    input.down_pressed = rl.IsKeyPressed(.DOWN)

    input.jump = rl.IsKeyDown(.SPACE)
    input.jump_pressed = rl.IsKeyPressed(.SPACE)

    input.ctrl = rl.IsKeyDown(.LEFT_CONTROL)
    input.ctrl_pressed = rl.IsKeyPressed(.LEFT_CONTROL)

    input.restart_pressed = rl.IsKeyPressed(.R)
}