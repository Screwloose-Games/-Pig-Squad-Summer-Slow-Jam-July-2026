class_name JunkSpawner
extends Marker2D

## Periodically lobs junk into the arena with variation in angle, speed and spin.
## Place one on each side; the right-hand one uses flip_horizontal to throw inward.

@export var junk_scene: PackedScene
## Where spawned junk is parented. Should be a shared container in the level,
## NOT this spawner, so items don't move if the spawner ever moves.
@export var spawn_container_path: NodePath

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

@onready var _timer: Timer = $Timer
var _container: Node


func _ready() -> void:
	if junk_scene == null:
		junk_scene = preload("res://junk/junk_item.tscn")
	_container = get_node_or_null(spawn_container_path)
	if _container == null:
		_container = get_parent()
	_timer.timeout.connect(_on_timer_timeout)
	_restart_timer()


func _restart_timer() -> void:
	var jitter := randf_range(-interval_jitter, interval_jitter)
	_timer.start(maxf(0.05, spawn_interval + jitter))


func _on_timer_timeout() -> void:
	if spawning_enabled:
		_spawn_one()
	_restart_timer()


func _spawn_one() -> void:
	var junk := junk_scene.instantiate()
	_container.add_child(junk)
	junk.global_position = global_position

	var angle := deg_to_rad(randf_range(angle_min_deg, angle_max_deg))
	var dir := Vector2.RIGHT.rotated(angle)
	if flip_horizontal:
		dir.x = -dir.x
	var speed := randf_range(speed_min, speed_max)

	if junk is RigidBody2D:
		junk.linear_velocity = dir * speed
		junk.angular_velocity = randf_range(-spawn_angular_velocity, spawn_angular_velocity)
