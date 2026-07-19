extends Node2D

## Red/green durability pie floating above an equipment item: green wedge = wear left,
## red = spent. Hidden unless the DragController marks the item hovered or dragged
## (Item.set_durability_shown), so the pile isn't a wall of gauges.

const RADIUS := 11.0
const OFFSET := Vector2(0.0, -44.0)
const SEGMENTS := 24
const RIM_COLOR := Color(0.08, 0.08, 0.08, 0.85)
const SPENT_COLOR := Color(0.78, 0.22, 0.2)
const LEFT_COLOR := Color(0.28, 0.75, 0.32)

var _item: Item


func _ready() -> void:
	_item = get_parent() as Item
	visible = false
	z_index = 20


func _process(_delta: float) -> void:
	if not visible or _item == null:
		return
	# The item body tumbles freely; pin the pie upright above it in world space.
	global_position = _item.global_position + OFFSET
	global_rotation = 0.0


func _draw() -> void:
	if _item == null or not _item.is_equipment():
		return
	var max_durability: int = _item.definition.equipment.max_durability
	var frac := clampf(float(_item.durability) / float(maxi(1, max_durability)), 0.0, 1.0)
	draw_circle(Vector2.ZERO, RADIUS + 2.0, RIM_COLOR)
	draw_circle(Vector2.ZERO, RADIUS, SPENT_COLOR)
	if frac >= 1.0:
		draw_circle(Vector2.ZERO, RADIUS, LEFT_COLOR)
	elif frac > 0.0:
		# Wedge fan from the top (-PI/2), clockwise through the remaining fraction.
		var points := PackedVector2Array([Vector2.ZERO])
		for i in SEGMENTS + 1:
			var angle := -PI / 2.0 + TAU * frac * float(i) / float(SEGMENTS)
			points.append(Vector2(cos(angle), sin(angle)) * RADIUS)
		draw_colored_polygon(points, LEFT_COLOR)
