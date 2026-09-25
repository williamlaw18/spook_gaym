class_name CavernEntrance
extends Node3D
## The way down from the homebase into the caverns. Using it emits `entered`;
## the homebase passes that on so Main can switch modes. The doorway is
## placeholder geometry until the entrance itself is designed.
## See docs/policies/interaction.md and docs/policies/dungeon-exploration.md.

signal entered

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)


func _on_interacted(_interactor: Interactor) -> void:
	# One use per visit: the homebase is replaced as soon as this is handled.
	_interactable.enabled = false
	entered.emit()
