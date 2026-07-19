class_name ItemSpawner
extends Marker2D

## Periodically lobs items into the arena with variation in type, angle, speed and spin.
## Place one on each side; the right-hand one uses flip_horizontal to throw inward.

@export var item_scene: PackedScene

@export_group("Items")
## Types this spawner throws, weighted by each def's spawn_weight; a def with weight 0 is
## disabled here. Authored on item_spawner.tscn so every instance throws the full mix
## without per-level wiring, while a level can still narrow it.
@export var item_defs: Array[ItemDef]

@export_group("Timing")
@export var spawn_interval: float = 1.2
@export var interval_jitter: float = 0.4

@export_group("Throw")
@export var speed_min: float = 500.0
@export var speed_max: float = 900.0
## Aim cone in degrees. 0 = straight right; negative aims upward
@export var angle_min_deg: float = -60.0
@export var angle_max_deg: float = -25.0
## Mirror the aim cone horizontally (use on a right-side spawner throwing left).
@export var flip_horizontal: bool = false
@export var spawn_angular_velocity: float = 6.0

@export var spawning_enabled: bool = true

var _container: Node

@onready var _timer: Timer = $Timer


func _ready() -> void:
	if item_scene == null:
		item_scene = preload("res://items/item.tscn")
	_timer.timeout.connect(_on_timer_timeout)
	_restart_timer()


## Sets where spawned items are parented. Injected by the ItemField so items land in a
## shared container rather than under this spawner, which would drag them along if the
## spawner ever moved. Falls back to the parent so a spawner dropped in on its own
## still works.
func setup(container: Node) -> void:
	_container = container


func _restart_timer() -> void:
	var jitter := randf_range(-interval_jitter, interval_jitter)
	_timer.start(maxf(0.05, spawn_interval + jitter))


func _on_timer_timeout() -> void:
	if spawning_enabled:
		_spawn_one()
	_restart_timer()


## Picks a type in proportion to the defs' spawn_weights. Weights are relative, so rarity
## is tuned by editing the defs rather than this function.
func _pick_def() -> ItemDef:
	var total := 0.0
	for def in item_defs:
		if def != null:
			total += maxf(0.0, def.spawn_weight)
	if total <= 0.0:
		return null
	var roll := randf() * total
	for def in item_defs:
		if def == null:
			continue
		roll -= maxf(0.0, def.spawn_weight)
		if roll <= 0.0:
			return def
	return null


func _spawn_one() -> void:
	# Resolved late, not in _ready(): children are ready before their parent, so an
	# ItemField has not had the chance to call setup() by the time _ready() runs here.
	if _container == null:
		_container = get_parent()

	var def := _pick_def()
	if def == null:
		push_warning("ItemSpawner has no usable item_defs; nothing to spawn.")
		return

	var item := item_scene.instantiate()
	# Assigned before add_child(), which is what runs _ready() and stamps the def onto the
	# body. Setting it afterwards would leave every item an unsized, untextured square.
	item.definition = def
	_container.add_child(item)
	item.global_position = global_position

	var angle := deg_to_rad(randf_range(angle_min_deg, angle_max_deg))
	var dir := Vector2.RIGHT.rotated(angle)
	if flip_horizontal:
		dir.x = -dir.x
	var speed := randf_range(speed_min, speed_max)

	if item is RigidBody2D:
		item.linear_velocity = dir * speed
		item.angular_velocity = randf_range(-spawn_angular_velocity, spawn_angular_velocity)

	GlobalSignalBus.item_spawned.emit(def)
