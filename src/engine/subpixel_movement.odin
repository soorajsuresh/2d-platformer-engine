package engine

import "core:math"

Subpixel_Movement :: struct {
    velocity: Vector2,
    displacement_remainder: Vector2
}

subpixel_move :: proc($T: typeid, object: ^T, speed: ^f32, remainder: ^f32, attempt_move: proc(object: ^T, offset: f32) -> bool, move: proc(object: ^T, offset: f32), collide: proc(object: ^T), dt: f32) {
    remainder^ += speed^ * dt
    displacement := math.round(remainder^)
    if displacement != 0 {
        remainder^ -= displacement
        step := sign(displacement)

        for displacement != 0 {
            if attempt_move(object, step) {
                move(object, step)
            } else {
                break
            }

            displacement -= step
        }
    } else if speed^ != 0 {
        if !attempt_move(object, sign(speed^)) {
            collide(object)
        }
    }
}