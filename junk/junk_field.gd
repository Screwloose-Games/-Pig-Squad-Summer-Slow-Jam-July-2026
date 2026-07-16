class_name JunkField
extends Node2D

## A self-contained pile of junk: the spawners that throw it in, the container it
## accumulates in, and the controller that lets the mouse drag it.
##
## Drop one into any scene and add JunkSpawners under Spawners; the wiring happens
## here. The host scene needs no script and no NodePaths pointing into this subtree.

@onready var junk_container: Node2D = %JunkContainer
@onready var _spawners: Node2D = %Spawners


func _ready() -> void:
	for spawner in _spawners.get_children():
		if spawner is JunkSpawner:
			spawner.setup(junk_container)


## Every JunkItem currently in the field. Useful for counting or clearing the pile.
func get_junk() -> Array[Node]:
	return junk_container.get_children()


## Turns every spawner on or off, e.g. to stop the pile growing once a round ends.
func set_spawning_enabled(enabled: bool) -> void:
	for spawner in _spawners.get_children():
		if spawner is JunkSpawner:
			spawner.spawning_enabled = enabled
