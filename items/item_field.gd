class_name ItemField
extends Node2D

## A self-contained pile of items: the spawners that throw them in, the container they
## accumulate in, and the controller that lets the mouse drag them.
##
## Drop one into any scene and add ItemSpawners under Spawners; the wiring happens
## here. The host scene needs no script and no NodePaths pointing into this subtree.

@onready var item_container: Node2D = %ItemContainer
@onready var _spawners: Node2D = %Spawners


func _ready() -> void:
	for spawner in _spawners.get_children():
		if spawner is ItemSpawner:
			spawner.setup(item_container)


## Every Item currently in the field. Useful for counting or clearing the pile.
func get_items() -> Array[Node]:
	return item_container.get_children()


## Turns every spawner on or off, e.g. to stop the pile growing once a round ends.
func set_spawning_enabled(enabled: bool) -> void:
	for spawner in _spawners.get_children():
		if spawner is ItemSpawner:
			spawner.spawning_enabled = enabled
