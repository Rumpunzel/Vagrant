@tool
class_name CatchBreaths
extends CharacterList

signal status_changed(can_catch_breath: bool)

@export_group("Configuration")
@export var _catch_breath: PackedScene

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var catch_breath: CatchBreath = _catch_breath.instantiate()
	_character_list.add(catch_breath)

func _create_character_entry(character: Character) -> Control:
	var catch_breath: CatchBreath = _catch_breath.instantiate()
	catch_breath.character = character
	catch_breath.status_changed.connect(_on_status_changed)
	return catch_breath

func _get_catch_breaths() -> Array[CatchBreath]:
	var catch_breaths: Array[CatchBreath] = []
	catch_breaths.assign(_character_list.get_elements())
	return catch_breaths

func _on_status_changed() -> void:
	var catch_breaths: Array[CatchBreath] = _get_catch_breaths()
	if catch_breaths.is_empty():
		status_changed.emit(false)
		return
	for catch_breath: CatchBreath in catch_breaths:
		if not catch_breath.can_catch_breath():
			status_changed.emit(false)
			return
	status_changed.emit(true)

func _on_confirmed() -> void:
	for catch_breath: CatchBreath in _get_catch_breaths(): catch_breath.catch_breath()
