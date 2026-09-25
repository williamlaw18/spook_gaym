class_name InteractionPrompt
extends Label
## On-screen prompt for whatever an Interactor is focused on, e.g.
## "Press E to enter". The key is read from the "interact" action (see
## InputLabels), so it follows rebinding and keyboard layout.
## See docs/policies/interaction.md.

const ACTION := &"interact"

@export var interactor: Interactor


func _ready() -> void:
	hide()
	if interactor:
		interactor.focus_changed.connect(_on_focus_changed)
	else:
		push_warning("InteractionPrompt has no Interactor assigned.")


func _on_focus_changed(interactable: Interactable) -> void:
	visible = interactable != null
	if interactable:
		text = "Press %s to %s" % [InputLabels.key_for(ACTION), interactable.prompt]

