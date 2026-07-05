package engine
import rl "vendor:raylib"

CollisionRectangle :: struct {
    offset: Vector2,
    size: Vector2
}

entities_intersect :: proc(a, b: Entity) -> bool {
    return rectangles_intersect(a.collision_rectangle, b.collision_rectangle)
}

rectangles_intersect :: proc(a, b: CollisionRectangle) -> bool {
    return a.offset.x < b.offset.x + b.size.x &&
           a.offset.x + a.size.x > b.offset.x &&
           a.offset.y < b.offset.y + b.size.y &&
           a.offset.y + a.size.y > b.offset.y
}

entities_intersect_at :: proc(a, b: Entity, offset: Vector2) -> bool {
    return rectangles_intersect_at(a.collision_rectangle, b.collision_rectangle, offset)
}

rectangles_intersect_at :: proc(a, b: CollisionRectangle, offset: Vector2) -> bool {
    r := a
    r.offset = add(r.offset, offset)
    return rectangles_intersect(r, b)
}

entity_intersecting_solid :: proc(e: Entity, ignore: ^Block) -> ^Block {
    return intersecting_solid(e.collision_rectangle, ignore)
}

intersecting_solid :: proc(a: CollisionRectangle, ignore: ^Block) -> ^Block {
    for &block in blocks {
        if rectangles_intersect(a, block.entity.collision_rectangle) && block.type == .Solid && &block != ignore {
            return &block
        }
    }
    return nil
}

entity_intersecting_solid_at :: proc(e: Entity, offset: Vector2, ignore: ^Block = nil) -> ^Block {
    return intersecting_solid_at(e.collision_rectangle, offset, ignore)
}

intersecting_solid_at :: proc(a: CollisionRectangle, offset: Vector2, ignore: ^Block = nil) -> ^Block {
    rect := a
    rect.offset = add(rect.offset, offset)
    return intersecting_solid(rect, ignore)
}

entity_intersecting_solids_at :: proc(e: Entity, offset: Vector2, ignore: ^Block = nil) -> [dynamic]^Block {
    return intersecting_solids_at(e.collision_rectangle, offset, ignore)
}

intersecting_solids_at :: proc(a: CollisionRectangle, offset: Vector2, ignore: ^Block = nil) -> [dynamic]^Block {
    rect := a
    rect.offset = add(rect.offset, offset)
    return intersecting_solids(rect, ignore)
}

intersecting_solids :: proc(a: CollisionRectangle, ignore: ^Block) -> [dynamic]^Block {
    solids : [dynamic]^Block
    for &block in blocks {
        if rectangles_intersect(a, block.entity.collision_rectangle) && block.type == .Solid && &block != ignore {
            append(&solids, &block)
        }
    }
    return solids
}

collision_rectangle_render :: proc(r: ^CollisionRectangle) {
    rect := rl.Rectangle{r.offset.x, r.offset.y, r.size.x, r.size.y}
    rl.DrawRectangleLinesEx(rect, 1, rl.Fade(rl.YELLOW, 0.5))
}