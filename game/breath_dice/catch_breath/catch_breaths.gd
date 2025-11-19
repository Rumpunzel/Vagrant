@tool
class_name CatchBreaths
extends CharacterList

signal caught_breath

@export_group("Configuration")
@export var _catch_breath: PackedScene

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var catch_breath: CatchBreath = _catch_breath.instantiate()
	_character_list.add(catch_breath)

func _create_character_entry(character: Character) -> Control:
	var catch_breath: CatchBreath = _catch_breath.instantiate()
	catch_breath.character = character
	return catch_breath

func _get_catch_breaths() -> Array[CatchBreath]:
	var catch_breaths: Array[CatchBreath] = []
	catch_breaths.assign(_character_list.get_elements())
	return catch_breaths

func _on_confirmed() -> void:
	for catch_breath: CatchBreath in _get_catch_breaths(): catch_breath.catch_breath()#
	caught_breath.emit()
