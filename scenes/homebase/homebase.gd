class_name Homebase
extends Node3D
## The surface homebase/factory: the safe(ish) mode. Resources come back here
## and monsters are assembled at separate crafting stations.
## See docs/policies/core-loop.md and docs/policies/monster-creation.md.

## The player used the cavern entrance. Main handles the mode switch.
signal cavern_requested


func _on_cavern_entrance_entered() -> void:
	cavern_requested.emit()
