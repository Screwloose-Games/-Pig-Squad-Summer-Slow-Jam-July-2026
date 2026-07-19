@tool
extends Node2D
## Back-view gladiator cut-out rig.

const SWORD_PROP_PATH := ^"Skeleton2D/Hip/Torso/UpperArmR/LowerArmR/SwordProp"
const HELMET_PROP_PATH := ^"Skeleton2D/Hip/Torso/Head/HelmetProp"

## When true, the sword prop is shown attached to the right hand.
@export var sword_equipped := true:
	set(value):
		sword_equipped = value
		_update_equipment()

## When true, the helmet prop is shown attached to the head.
@export var helmet_equipped := false:
	set(value):
		helmet_equipped = value
		_update_equipment()

func _ready() -> void:
	_update_equipment()

func _update_equipment() -> void:
	var sword: Sprite2D = get_node_or_null(SWORD_PROP_PATH)
	if sword:
		sword.visible = sword_equipped
	var helmet: Sprite2D = get_node_or_null(HELMET_PROP_PATH)
	if helmet:
		helmet.visible = helmet_equipped
