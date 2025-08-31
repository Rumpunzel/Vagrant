class_name DiceLog
extends PanelContainer

signal entry_added(entry: Control)

@export var _characters: Characters

@export_group("Configuration")
@export var _scroll_container: ScrollContainer
@export var _log_entries: Container
@export var _dice_log_die_entry: PackedScene
@export var _dice_log_entry_group: PackedScene

var _current_entry_group: DiceLogEntryGroup = null
var _protagonist: Character :
	set(new_protagonist):
		if _protagonist: _protagonist.save_rolled.disconnect(_on_save_rolled)
		_protagonist = new_protagonist
		_protagonist.save_rolled.connect(_on_save_rolled)

func _ready() -> void:
	_characters.characters_updated.connect(_on_characters_updated)
	DiceRoller.die_rolled.connect(_on_die_rolled)

func _exit_tree() -> void:
	_characters.characters_updated.disconnect(_on_characters_updated)
	DiceRoller.die_rolled.disconnect(_on_die_rolled)

func _on_characters_updated(_updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	_protagonist = _characters.get_protagonist()

func _on_die_rolled(die: Die) -> void:
	var dice_log_entry: DiceLogDieEntry = _dice_log_die_entry.instantiate()
	_log_entries.add_child(dice_log_entry)
	dice_log_entry.initialize_die_result(die)

func _on_save_rolled(save_result: SaveResult) -> void:
	if _current_entry_group == null or _current_entry_group.character_profile != save_result.save_request.character_profile:
		if _current_entry_group != null: _current_entry_group.entry_added.disconnect(_on_entry_entered_tree)
		_current_entry_group = _dice_log_entry_group.instantiate()
		_current_entry_group.character_profile = save_result.save_request.character_profile
		_current_entry_group.entry_added.connect(_on_entry_entered_tree)
		_log_entries.add_child(_current_entry_group)
	_current_entry_group.add_entry(save_result, _characters.get_character)

func _on_entry_entered_tree(node: Node) -> void:
	if not node is Control: return
	await get_tree().process_frame
	_scroll_container.ensure_control_visible(node as Control)
	entry_added.emit(node)
