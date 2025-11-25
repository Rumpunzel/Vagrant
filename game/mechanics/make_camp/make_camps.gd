@tool
class_name MakeCamps
extends CharacterList

signal status_changed(can_catch_breath: bool)

func _create_character_entry(character: Character) -> Control:
	#var catch_breath: CatchBreath = _catch_breath.instantiate()
	#catch_breath.character = character
	#catch_breath.status_changed.connect(_on_status_changed)
	#return catch_breath
	return Control.new()

func _on_status_changed() -> void:
	#var catch_breaths: Array[CatchBreath] = _get_catch_breaths()
	#if catch_breaths.is_empty():
		#status_changed.emit(false)
		#return
	#for catch_breath: CatchBreath in catch_breaths:
		#if not catch_breath.can_catch_breath():
			#status_changed.emit(false)
			#return
	status_changed.emit(true)

func _on_confirmed() -> void:
	for character: Character in party.characters.values(): character.exhaustion = []
