class_name DiceLogEntryGroup
extends PanelContainer

signal entry_added(entry: Control)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _entries: Container
@export var _dice_log_save_result_entry: PackedScene

var character_profile: CharacterProfile :
	set(new_character_profile):
		character_profile = new_character_profile
		_portrait.texture = character_profile.portrait

func add_entry(save_result: SaveResult, character_resolver: Callable) -> void:
	var dice_log_entry: DiceLogSaveResultEntry = _dice_log_save_result_entry.instantiate()
	_entries.add_child(dice_log_entry)
	dice_log_entry.initialize_save_result(save_result, character_resolver)
	entry_added.emit(dice_log_entry)
