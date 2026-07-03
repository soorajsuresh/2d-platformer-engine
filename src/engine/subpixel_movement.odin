package engine

import "core:math"

Subpixel_Movement :: struct {
    velocity: Vector2,
    displacement_remainder: Vector2
}

subpixel_move :: proc(position: ^Vector2, velocity: ^Vector2, movement: ^Subpixel_Movement, dt: f32, ) {
    
    // vertical
    movement.displacement_remainder.y += velocity.y * dt
    displacement := math.round(movement.displacement_remainder.y)
    if displacement != 0 {
        movement.displacement_remainder.y -= displacement
        step := sign(displacement)

        for displacement != 0 {
            // check collision -> break

            position.y += step
            
        }
    }
}