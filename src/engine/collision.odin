package engine
import rl "vendor:raylib"

// TODO: Did a bulk change of passing in scene and actor; maybe not all the functions need this; have not thought about it

CollisionRectangle :: struct {
    offset: Vector2,
    size: Vector2
}

colliders_intersect :: proc(a, b: Collider) -> bool {
    return rectangles_intersect(a.collision_rectangle, b.collision_rectangle)
}

rectangles_intersect :: proc(a, b: CollisionRectangle) -> bool {
    return a.offset.x < b.offset.x + b.size.x &&
           a.offset.x + a.size.x > b.offset.x &&
           a.offset.y < b.offset.y + b.size.y &&
           a.offset.y + a.size.y > b.offset.y
}

colliders_intersect_at :: proc(a, b: Collider, offset: Vector2) -> bool {
    return rectangles_intersect_at(a.collision_rectangle, b.collision_rectangle, offset)
}

rectangles_intersect_at :: proc(a, b: CollisionRectangle, offset: Vector2) -> bool {
    r := a
    r.offset = add(r.offset, offset)
    return rectangles_intersect(r, b)
}

collider_intersecting_solid :: proc(scene: ^Scene, actor: Actor, e: Collider, ignore: ^Block) -> ^Block {
    return intersecting_solid(scene, actor, e.collision_rectangle, ignore)
}

intersecting_solid :: proc(scene: ^Scene, actor: Actor, a: CollisionRectangle, ignore: ^Block) -> ^Block {
    for actor, &block in scene.blocks {
        if rectangles_intersect(a, block.collider.collision_rectangle) && block.type == .Solid && &block != ignore {
            return &block
        }
    }
    return nil
}

collider_intersecting_solid_at :: proc(scene: ^Scene, actor: Actor, e: Collider, offset: Vector2, ignore: ^Block = nil) -> ^Block {
    return intersecting_solid_at(scene, actor, e.collision_rectangle, offset, ignore)
}

intersecting_solid_at :: proc(scene: ^Scene, actor: Actor, a: CollisionRectangle, offset: Vector2, ignore: ^Block = nil) -> ^Block {
    rect := a
    rect.offset = add(rect.offset, offset)
    return intersecting_solid(scene, actor, rect, ignore)
}

collider_intersecting_solids_at :: proc(scene: ^Scene, e: Collider, offset: Vector2, ignore: ^Block = nil) -> [dynamic]^Block {
    return intersecting_solids_at(scene, e.collision_rectangle, offset, ignore)
}

intersecting_solids_at :: proc(scene: ^Scene, a: CollisionRectangle, offset: Vector2, ignore: ^Block = nil) -> [dynamic]^Block {
    rect := a
    rect.offset = add(rect.offset, offset)
    return intersecting_solids(scene, rect, ignore)
}

intersecting_solids :: proc(scene: ^Scene, a: CollisionRectangle, ignore: ^Block) -> [dynamic]^Block {
    solids : [dynamic]^Block
    for actor, &block in scene.blocks {
        if rectangles_intersect(a, block.collider.collision_rectangle) && block.type == .Solid && &block != ignore {
            append(&solids, &block)
        }
    }
    return solids
}

collision_rectangle_render :: proc(r: ^CollisionRectangle) {
    rect := rl.Rectangle{r.offset.x, r.offset.y, r.size.x, r.size.y}
    rl.DrawRectangleLinesEx(rect, 1, rl.Fade(rl.YELLOW, 0.5))
}