class_name BattleEndOverlay
extends CanvasLayer
## Victory/defeat panel with a restart button.
##
## Shows itself off GlobalSignalBus.battle_ended and never holds a reference to the
## units or to the controller that ran the fight — the same contract BattleNameplate
## keeps. Drop it into any scene that emits battle_ended and it works.

## Beat between the killing blow and the panel, so the death animation can play out.
@export var death_anim_wait: float = 0.8
@export var victory_text: String = "Victory!"
@export var defeat_text: String = "Defeat"

@onready var _overlay_root: Control = %OverlayRoot
@onready var _result_label: Label = %ResultLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_overlay_root.visible = false
	GlobalSignalBus.battle_ended.connect(_on_battle_ended)
	_restart_button.pressed.connect(_on_restart_pressed)


func _on_battle_ended(hero_won: bool) -> void:
	await get_tree().create_timer(death_anim_wait).timeout
	# The scene can be torn down during the wait (a restart, say), so re-check.
	if not is_inside_tree():
		return
	_result_label.text = victory_text if hero_won else defeat_text
	_overlay_root.visible = true


func _on_restart_pressed() -> void:
	GlobalSignalBus.ui_button_pressed.emit()
	get_tree().reload_current_scene()
