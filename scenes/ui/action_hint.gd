class_name ActionHint
extends Label
## A fixed on-screen hint for an input action, e.g. "Press M for debug map".
## The key is read from the action, so it follows rebinding.

@export var action := &""
## Hint text; %s is replaced with the action's key.
@export var text_format := "Press %s"


func _ready() -> void:
	text = text_format % InputLabels.key_for(action)
