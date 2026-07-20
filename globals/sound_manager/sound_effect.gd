class_name SoundEffectConnector
extends Node

# extends: https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-error
enum TryConnectError {
	INSTANCE_INVALID = 49,
	NO_SIGNAL_NAME = 50,
	NO_MATCHING_SIGNAL_NAME = 51,
}

@export var player_type: GSoundManager.SoundPlayerType
@export_enum("GlobalSignalBus", "QuestManager", "EnvironmentManager", "StructureManager")
var global_name: String
@export var start_signal_name: String
@export var stop_signal_name: String
@export var sound_effect: AudioStream

var try_connect_start_result: int = FAILED
var try_connect_stop_result: int = FAILED

@onready var signal_node = get_tree().get_root().get_node(global_name)
@onready var sound_manager = get_parent()


func _ready() -> void:
	try_connect_stop_signal()
	try_connect_start_signal()


func try_connect_start_signal() -> int:
	signal_node = get_tree().get_root().get_node(global_name)
	sound_manager = get_parent()

	if not is_instance_valid(signal_node):
		try_connect_start_result = TryConnectError.INSTANCE_INVALID
		return TryConnectError.INSTANCE_INVALID

	if start_signal_name == "":
		try_connect_start_result = TryConnectError.NO_SIGNAL_NAME
		return TryConnectError.NO_SIGNAL_NAME

	if not signal_node.has_signal(start_signal_name):
		try_connect_start_result = TryConnectError.NO_MATCHING_SIGNAL_NAME
		return TryConnectError.NO_MATCHING_SIGNAL_NAME

	try_connect_start_result = signal_node.connect(start_signal_name, _on_start)
	return try_connect_start_result


func try_connect_stop_signal() -> int:
	signal_node = get_tree().get_root().get_node(global_name)
	sound_manager = get_parent()

	if not is_instance_valid(signal_node):
		try_connect_stop_result = TryConnectError.INSTANCE_INVALID
		return TryConnectError.INSTANCE_INVALID

	if stop_signal_name == "":
		try_connect_stop_result = TryConnectError.NO_SIGNAL_NAME
		return TryConnectError.NO_SIGNAL_NAME

	if not signal_node.has_signal(stop_signal_name):
		try_connect_stop_result = TryConnectError.NO_MATCHING_SIGNAL_NAME
		return TryConnectError.NO_MATCHING_SIGNAL_NAME

	try_connect_stop_result = signal_node.connect(stop_signal_name, _on_stop)
	return try_connect_stop_result


# The optional arguments are how this connector binds a signal that carries a payload —
# the gameplay signals on GlobalSignalBus report what happened, and a connector that only
# plays one sound has no use for the detail. Four covers every signal on the bus today.
# A signal with more arguments than this simply cannot be wired here.
func _on_start(_a = null, _b = null, _c = null, _d = null) -> void:
	sound_manager.play_sound(sound_effect, player_type)


func _on_stop(_a = null, _b = null, _c = null, _d = null) -> void:
	sound_manager.stop_sound(player_type)
