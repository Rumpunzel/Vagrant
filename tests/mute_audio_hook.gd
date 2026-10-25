extends GdUnitTestSessionHook

## Mutes all audio while tests run (dice, injuries, success/failure sounds), and restores it afterwards.
## Registered in project.godot under gdunit4/hooks/session_hooks.

var _was_muted: bool = false

func _init() -> void:
	super("Mute audio", "Mutes the Master audio bus for the duration of the test session.")

func startup(_session: GdUnitTestSession) -> GdUnitResult:
	var master: int = AudioServer.get_bus_index("Master")
	_was_muted = AudioServer.is_bus_mute(master)
	AudioServer.set_bus_mute(master, true)
	return GdUnitResult.success()

func shutdown(_session: GdUnitTestSession) -> GdUnitResult:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), _was_muted)
	return GdUnitResult.success()
