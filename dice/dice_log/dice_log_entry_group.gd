class_name DiceLogEntryGroup
extends PanelContainer

signal entry_added(entry: Control)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _entries: Container
@export var _dice_log_entry: PackedScene

var character: Character :
	set(new_character):
		character = new_character
		_portrait.texture = character.portrait

func add_entry(save_result: SaveResult) -> void:
	var dice_log_entry: DiceLogEntry = _dice_log_entry.instantiate()
	dice_log_entry.initialize_save_result(save_result)
	_entries.add_child(dice_log_entry)
	entry_added.emit(dice_log_entry)
