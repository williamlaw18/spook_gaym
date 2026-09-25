class_name InputLabels
## Display names for the keys bound to input actions, for on-screen hints.


## The key bound to `action`, as shown on this keyboard layout (actions are
## bound by physical key). Falls back to the event's own text, or the action
## name if nothing is bound.
static func key_for(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key:
			# The headless display server can't map layouts.
			if DisplayServer.get_name() == "headless":
				return key.as_text_physical_keycode()
			return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode))
		return event.as_text()
	return String(action)
