@tool
class_name ItemArena
extends StaticBody2D

## Static floor and side walls that keep items in the play area.
##
## The collision shapes and the drawn visuals are both generated from the exports
## below, so the two cannot drift apart the way hand-placed shapes and matching
## Polygon2Ds do. @tool so the box is visible while placing it in the editor.
##
## The collision_mask stays empty: items scan the world layer, the world never scans
## back. See ItemObstacle for why nothing static in this project scans.

## Inner play area, centred on this node. The walls flank it and the floor caps it,
## so the floor's top surface sits at arena_size.y / 2.
@export var arena_size: Vector2 = Vector2(1220, 660):
	set(value):
		arena_size = value
		_rebuild()
## Thickness of the floor slab and of each wall.
@export var wall_thickness: float = 40.0:
	set(value):
		wall_thickness = value
		_rebuild()
@export var wall_color: Color = Color(0.09, 0.11, 0.09):
	set(value):
		wall_color = value
		queue_redraw()

@onready var _floor: CollisionShape2D = %Floor
@onready var _left_wall: CollisionShape2D = %LeftWall
@onready var _right_wall: CollisionShape2D = %RightWall


func _ready() -> void:
	_rebuild()


func _draw() -> void:
	for rect in _slab_rects():
		draw_rect(rect, wall_color)


## Floor, left wall and right wall, in that order. The single source the shapes and
## the visuals are both built from.
func _slab_rects() -> Array[Rect2]:
	var half: Vector2 = arena_size * 0.5
	var floor_rect := Rect2(
		Vector2(-half.x - wall_thickness, half.y),
		Vector2(arena_size.x + wall_thickness * 2.0, wall_thickness)
	)
	var left_rect := Rect2(
		Vector2(-half.x - wall_thickness, -half.y), Vector2(wall_thickness, arena_size.y)
	)
	var right_rect := Rect2(Vector2(half.x, -half.y), Vector2(wall_thickness, arena_size.y))
	return [floor_rect, left_rect, right_rect]


func _rebuild() -> void:
	# Setters fire while the scene is still loading; _ready() rebuilds once nodes exist.
	if not is_node_ready():
		return
	var rects: Array[Rect2] = _slab_rects()
	_apply_rect(_floor, rects[0])
	_apply_rect(_left_wall, rects[1])
	_apply_rect(_right_wall, rects[2])
	queue_redraw()


func _apply_rect(shape_node: CollisionShape2D, rect: Rect2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape_node.shape = rectangle
	shape_node.position = rect.get_center()
