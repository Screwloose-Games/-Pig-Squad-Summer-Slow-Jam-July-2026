class_name BattleUnit
extends Node2D
## A stationary auto-battle unit that attacks its target on a rhythm.
## Every attack hits automatically — no collision detection. Damage is
## applied by the attack animation's method track at the lunge apex.
##
## Cadence comes from the unit's AttackPattern: this scrubs a playhead along that looping
## timeline and swings on each beat it crosses. Anything that makes a unit fight faster or
## slower scales the playhead, so it bends the whole rhythm rather than one interval.

## Which gladiator this is. Picks the per-side signals emitted on the bus, so
## UI can listen for one fighter without holding a reference to it.
enum Side { HERO, ENEMY }

@export var stats: UnitStats
@export var side: BattleUnit.Side = BattleUnit.Side.HERO
@export var facing_left: bool = false
@export var flash_duration: float = 0.08
@export var shake_amplitude: float = 2.5
@export var shake_duration: float = 0.10
## Thickness (in texels) of the drop-target outline set_outline draws around the sprite.
## Texels, not pixels: the gladiator art renders at roughly two-thirds texture scale,
## so this reads about half as wide on screen.
@export var outline_width: float = 12.0

var target: BattleUnit

## Optional wearable-gear component; an EquipmentComponent mounted under this unit
## assigns itself here during its own _ready(). Null means the pre-equipment
## behavior below, which is every enemy and every scene without items.
var equipment: EquipmentComponent

var _flash_tween: Tween
var _shake_tween: Tween

## The unit's cadence. Resolved from stats once, so a null pattern costs nothing per frame.
var _pattern: AttackPattern
var _fighting: bool = false
## Position along the pattern's loop, in seconds, kept within [0, pattern.duration).
var _playhead: float = 0.0
## Index into pattern.beats of the next beat this unit owes.
var _next_beat: int = 0

@onready var visuals: Node2D = %Visuals
@onready var sprite: Node2D = %Sprite
@onready var health_component: HealthComponent = %HealthComponent
@onready var stamina_component: StaminaComponent = %StaminaComponent
@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_apply_stats()
	visuals.scale.x = -1.0 if facing_left else 1.0
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	stamina_component.stamina_changed.connect(_on_stamina_changed)
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("idle_bob")


func _process(delta: float) -> void:
	if not _fighting or _pattern == null:
		return
	if _pattern.duration <= 0.0 or _pattern.beats.is_empty():
		return
	_playhead += delta * _speed_scale()
	# Walk the timeline rather than testing it once, so a frame that steps over several beats —
	# a long hitch, or a loop shorter than the frame — fires them all in order instead of
	# silently dropping attacks. Terminates because every iteration either consumes a beat or
	# subtracts a duration the guard above proved positive.
	while true:
		if _next_beat < _pattern.beats.size():
			if _playhead < _pattern.beats[_next_beat]:
				return
			_fire_beat()
			_next_beat += 1
		else:
			if _playhead < _pattern.duration:
				return
			_playhead -= _pattern.duration
			_next_beat = 0


func setup(new_target: BattleUnit) -> void:
	target = new_target


## Re-seed the unit, optionally as a different stat block, and put it back on its feet ready to
## fight again. Exists for swapping a unit's identity after it is already in the tree, which the
## editor-placed gladiators need since _apply_stats() runs during their own _ready().
func reset_for_new_fight(new_stats: UnitStats = null) -> void:
	if new_stats != null:
		stats = new_stats
	stop_fighting()
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_apply_stats()
	_clear_flash()
	# The death animation leaves the sprite rotated and faded out, and idle_bob only drives
	# position — so without clearing these by hand a revived unit stands up still lying down
	# and invisible.
	sprite.rotation = 0.0
	sprite.position = Vector2.ZERO
	sprite.self_modulate = Color.WHITE
	visuals.position = Vector2.ZERO
	animation_player.play("idle_bob")


func start_fighting() -> void:
	# Rewind to the head of the loop. A beat at 0.0 lands on the first frame, so a fight opens
	# with a swing rather than a dead beat.
	_playhead = 0.0
	_next_beat = 0
	_fighting = true


func stop_fighting() -> void:
	_fighting = false


func take_damage(amount: int) -> void:
	if not is_alive():
		return
	# Armor soaks first, and the mitigated number is what every listener hears, so
	# damage numbers and nameplates tell the truth. A fully absorbed hit still flashes
	# and shows a 0 — honest feedback that the armor ate it (and wore down for it).
	var final_amount := amount
	if equipment != null:
		final_amount = equipment.absorb_hit(amount)
	health_component.take_damage(final_amount)
	GlobalSignalBus.unit_hurt.emit(self, final_amount)
	_emit_hurt(final_amount)
	if is_alive():
		_play_hit_react()


func is_alive() -> bool:
	return health_component.is_alive()


func _apply_stats() -> void:
	if stats == null:
		return
	# Team tint rides on modulate; the death animation fades self_modulate, so the
	# two multiply together instead of one clobbering the other.
	sprite.modulate = stats.body_color
	_pattern = _resolve_pattern()
	health_component.initialize(stats.max_health)
	stamina_component.initialize(stats.max_stamina)


func _resolve_pattern() -> AttackPattern:
	if stats.pattern != null:
		return stats.pattern
	# No pattern authored: a plain attack_interval means the same thing as a loop that long with
	# a single beat at its head, so stat blocks predating patterns keep their exact cadence.
	var steady := AttackPattern.new()
	steady.duration = stats.attack_interval
	steady.beats = [0.0]
	return steady


func _speed_scale() -> float:
	# Out of stamina → the rhythm plays at half speed. Scaling the playhead rather than one
	# interval means a shaped pattern stretches whole: a rogue exhausted still fights in a 1-2
	# and a gap, just a slower one. The coming stamina system drives this same number.
	return 1.0 if stamina_component.has_stamina() else 0.5


func _emit_hurt(amount: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_hurt.emit(amount)
	else:
		GlobalSignalBus.enemy_gladiator_hurt.emit(amount)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_health_changed.emit(current_health)
	else:
		GlobalSignalBus.enemy_gladiator_health_changed.emit(current_health)


func _on_stamina_changed(current_stamina: int, _max_stamina: int) -> void:
	if side == Side.HERO:
		GlobalSignalBus.hero_gladiator_stamina_changed.emit(current_stamina)
	else:
		GlobalSignalBus.enemy_gladiator_stamina_changed.emit(current_stamina)


func _play_hit_react() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
		_clear_flash()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		visuals.position = Vector2.ZERO
	sprite.material.set_shader_parameter(&"flash_amount", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(flash_duration)
	_flash_tween.tween_callback(_clear_flash)
	_shake_tween = create_tween()
	var step_time: float = shake_duration / 4.0
	for i in 3:
		var offset := Vector2(
			randf_range(-shake_amplitude, shake_amplitude),
			randf_range(-shake_amplitude, shake_amplitude)
		)
		_shake_tween.tween_property(visuals, "position", offset, step_time)
	_shake_tween.tween_property(visuals, "position", Vector2.ZERO, step_time)


func _clear_flash() -> void:
	sprite.material.set_shader_parameter(&"flash_amount", 0.0)


## Shows/hides an outline around the sprite's silhouette. Used as the hover highlight
## while a usable item is dragged over this unit; safe alongside the hit flash because
## the material is local to each scene instance.
func set_outline(enabled: bool) -> void:
	sprite.material.set_shader_parameter(&"outline_width", outline_width if enabled else 0.0)


func _fire_beat() -> void:
	if not is_alive() or target == null or not target.is_alive():
		return
	stamina_component.consume(stats.stamina_cost)
	# Rewind before playing. play() on the already-playing attack would resume it rather than
	# restart it, so a burst's second swing would inherit the first's progress, sail past the
	# strike method track, and land no damage at all. seek() rather than stop()+play() so the
	# pose snapshot survives and cross-fade blend times still apply.
	animation_player.play(&"attack")
	animation_player.seek(0.0, true)
	GlobalSignalBus.unit_attacked.emit(self, target)


func _on_attack_strike() -> void:
	# Called by the attack animation's method track at the lunge apex.
	if not is_alive() or target == null or not target.is_alive():
		return
	var damage := stats.damage
	if equipment != null:
		damage = equipment.roll_attack_damage(stats.damage)
	target.take_damage(damage)


func _on_died() -> void:
	stop_fighting()
	animation_player.play("death")
	GlobalSignalBus.unit_died.emit(self)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"attack" and is_alive():
		animation_player.play("idle_bob")
