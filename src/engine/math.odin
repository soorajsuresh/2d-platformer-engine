package engine

sign :: proc(x: f32) -> f32 {
    return 1 if x > 0 else -1 if x < 0 else 0
}

Vector2 :: struct {
    x, y: f32
}

add :: proc(a, b: Vector2) -> Vector2 {
    return Vector2{a.x + b.x, a.y + b.y}
}

scale :: proc(a: f32, b: Vector2) -> Vector2 {
    return Vector2{a * b.x, a * b.y}
}

subtract :: proc(a, b: Vector2) -> Vector2 {
    return add(a, scale(-1, b))
}

zero :: proc(a: Vector2) -> bool {
    return a.x == 0 && a.y == 0
}