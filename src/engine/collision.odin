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

collider_intersecting_solid_actor_when_offset :: proc(scene: ^Scene, c: Collider, offset: Vector2, ignore: ^Block = nil) -> Actor {
    offset_collider := c
    offset_collider.collision_rectangle.offset = add(offset_collider.collision_rectangle.offset, offset)
    return collider_intersecting_solid_actor(scene, offset_collider, ignore)
}

collider_intersecting_solid_actors_when_offset :: proc(scene: ^Scene, c: Collider, offset: Vector2, ignore: ^Block = nil) -> [dynamic]Actor {
    offset_collider := c
    offset_collider.collision_rectangle.offset = add(offset_collider.collision_rectangle.offset, offset)
    return collider_intersecting_solid_actors(scene, offset_collider, ignore)
}

colliders_intersect :: proc(c, d: Collider) -> bool {
    return rectangles_intersect(c.collision_rectangle, d.collision_rectangle)
}

collider_intersecting_solid_actor :: proc(scene: ^Scene, c: Collider, ignore: ^Block) -> Actor {
    return rectangle_intersecting_solid_actor(scene, c.collision_rectangle, ignore)
}

collider_intersecting_solid_actors :: proc(scene: ^Scene, c: Collider, ignore: ^Block = nil) -> [dynamic]Actor {
    return rectangle_intersecting_solid_actors(scene, c.collision_rectangle, ignore)
}

rectangle_intersecting_solid_actor :: proc(scene: ^Scene, r: CollisionRectangle, ignore: ^Block) -> Actor {
    for actor, &block in scene.blocks {
        if &block != ignore && block.type == .Solid && rectangles_intersect(r, scene.colliders[actor].collision_rectangle)  {
            return actor
        }
    }
    return NO_ACTOR
}

rectangle_intersecting_solid_actors :: proc(scene: ^Scene, r: CollisionRectangle, ignore: ^Block) -> [dynamic]Actor {
    solids : [dynamic]Actor
    for actor, &block in scene.blocks {
        if &block != ignore && block.type == .Solid && rectangles_intersect(r, scene.colliders[actor].collision_rectangle) {
            append(&solids, actor)
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