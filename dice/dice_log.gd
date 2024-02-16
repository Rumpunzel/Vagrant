extends VBoxContainer

signal entry_added(entry: Control)

@export var _dice_log_entry: PackedScene
@export var _dice_log_entry_group: PackedScene

var _current_entry_group: DiceLogEntryGroup = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DiceRoller.save_rolled.connect(_on_save_rolled)

func _exit_tree() -> void:
	DiceRoller.save_rolled.disconnect(_on_save_rolled)

func _on_die_rolled(die: Die) -> void:
	var dice_log_entry: DiceLogEntry = _dice_log_entry.instantiate()
	dice_log_entry.initialize_die_result(die)
	add_child(dice_log_entry)

func _on_save_rolled(save_result: SaveResult) -> void:
	var dice_log_entry: DiceLogEntry = _dice_log_entry.instantiate()
	dice_log_entry.initialize_save_result(save_result)
	if _current_entry_group == null or _current_entry_group.character != save_result.character:
		if _current_entry_group != null: _current_entry_group.entry_added.disconnect(_on_entry_entered_tree)
		_current_entry_group = _dice_log_entry_group.instantiate()
		_current_entry_group.character = save_result.character
		_current_entry_group.entry_added.connect(_on_entry_entered_tree)
		add_child(_current_entry_group)
	_current_entry_group.add_entry(save_result)

func _on_entry_entered_tree(node: Node) -> void:
	if not node is Control: return
	await await get_tree().process_frame
	entry_added.emit(node)
