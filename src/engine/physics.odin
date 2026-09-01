package engine

import "vendor:box2d"

Physics :: struct {
	worldId: box2d.WorldId,
}

CreatePhysics :: proc() -> Physics {
	worldDef := box2d.DefaultWorldDef()
	worldDef.gravity = [2]f32{0, 10}
	worldId := box2d.CreateWorld(worldDef)

	return Physics{worldId = worldId}
}

StepPhysics :: proc(physics: ^Physics) {
	box2d.World_Step(physics.worldId, 1.0 / 60.0, 4)
}

DestroyPhysics :: proc(physics: ^Physics) {
	box2d.DestroyWorld(physics.worldId)
}

Body :: box2d.BodyId

GetBodyPos :: proc(body: Body) -> [2]f32 {
	return box2d.Body_GetPosition(body)
}

CreateRectangle :: proc(physics: ^Physics, pos: [2]f32, size: [2]f32, angle: f32) -> Body {
	bodyDef := box2d.DefaultBodyDef()
	bodyDef.type = .dynamicBody
	bodyDef.position = pos
	bodyDef.rotation = box2d.MakeRot(angle)
	bodyId := box2d.CreateBody(physics.worldId, bodyDef)

	shapeDef := box2d.DefaultShapeDef()
	shapeDef.density = 1
	box := box2d.MakeBox(size.x / 2, size.y / 2)
	shapeId := box2d.CreatePolygonShape(bodyId, shapeDef, &box)

	return bodyId
}

CreateBoundingBox :: proc(physics: ^Physics, rect: [4]f32) -> Body {
	x, y, w, h := rect[0], rect[1], rect[2], rect[3]

	bodyDef := box2d.DefaultBodyDef()
	bodyDef.type = .staticBody
	bodyDef.position = [2]f32{0, 0} // segments below are in world coords
	bodyId := box2d.CreateBody(physics.worldId, bodyDef)

	shapeDef := box2d.DefaultShapeDef()

	// corners (y-down: y is top, y+h is bottom)
	tl := [2]f32{x, y} // top-left
	tr := [2]f32{x + w, y} // top-right
	bl := [2]f32{x, y + h} // bottom-left
	br := [2]f32{x + w, y + h} // bottom-right

	top := box2d.Segment {
		point1 = tl,
		point2 = tr,
	}
	topId := box2d.CreateSegmentShape(bodyId, shapeDef, &top)

	bottom := box2d.Segment {
		point1 = bl,
		point2 = br,
	}
	bottomId := box2d.CreateSegmentShape(bodyId, shapeDef, &bottom)

	left := box2d.Segment {
		point1 = tl,
		point2 = bl,
	}
	leftId := box2d.CreateSegmentShape(bodyId, shapeDef, &left)

	right := box2d.Segment {
		point1 = tr,
		point2 = br,
	}
	rightId := box2d.CreateSegmentShape(bodyId, shapeDef, &right)

	return bodyId
}

DestroyBody :: proc(body: ^Body) {
	box2d.DestroyBody(body^)
}
