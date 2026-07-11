package engine
import rl "vendor:raylib"

CollisionRectangle :: struct {
    offset, size: Vector2,
}

colliders_intersect_when_offset :: proc(c, d: Collider, offset: Vector2) -> bool {
    offset_collider := c
    offset_collider.collision_rectangle.offset = add(offset_collider.collision_rectangle.offset, offset)
    return colliders_intersect(offset_collider, d)
}

collider_intersecting_solid_when_offset :: proc(scene: ^Scene, c: Collider, offset: Vector2, ignore: ^Block = nil) -> ^Block {
    offset_collider := c
    offset_collider.collision_rectangle.offset = add(offset_collider.collision_rectangle.offset, offset)
    return collider_intersecting_solid(scene, offset_collider, ignore)
}

collider_intersecting_solids_when_offset :: proc(scene: ^Scene, c: Collider, offset: Vector2, ignore: ^Block = nil) -> [dynamic]^Block {
    offset_collider := c
    offset_collider.collision_rectangle.offset = add(offset_collider.collision_rectangle.offset, offset)
    return collider_intersecting_solids(scene, offset_collider, ignore)
}

colliders_intersect :: proc(c, d: Collider) -> bool {
    return rectangles_intersect(c.collision_rectangle, d.collision_rectangle)
}

collider_intersecting_solid :: proc(scene: ^Scene, c: Collider, ignore: ^Block) -> ^Block {
    return rectangle_intersecting_solid(scene, c.collision_rectangle, ignore)
}

collider_intersecting_solids :: proc(scene: ^Scene, c: Collider, ignore: ^Block = nil) -> [dynamic]^Block {
    return rectangle_intersecting_solids(scene, c.collision_rectangle, ignore)
}

rectangle_intersecting_solid :: proc(scene: ^Scene, r: CollisionRectangle, ignore: ^Block) -> ^Block {
    for actor, &block in scene.blocks {
        if &block != ignore && block.type == .Solid && rectangles_intersect(r, block.collider.collision_rectangle)  {
            return &block
        }
    }
    return nil
}

rectangle_intersecting_solids :: proc(scene: ^Scene, r: CollisionRectangle, ignore: ^Block) -> [dynamic]^Block {
    solids : [dynamic]^Block
    for actor, &block in scene.blocks {
        if &block != ignore && block.type == .Solid && rectangles_intersect(r, block.collider.collision_rectangle) {
            append(&solids, &block)
        }
    }
    return solids
}

rectangles_intersect :: proc(r, s: CollisionRectangle) -> bool {
    return r.offset.x < s.offset.x + s.size.x &&
           r.offset.x + r.size.x > s.offset.x &&
           r.offset.y < s.offset.y + s.size.y &&
           r.offset.y + r.size.y > s.offset.y
}

collision_rectangle_render :: proc(r: ^CollisionRectangle) {
    rect := rl.Rectangle{r.offset.x, r.offset.y, r.size.x, r.size.y}
    rl.DrawRectangleLinesEx(rect, 1, rl.Fade(rl.YELLOW, 0.5))
}