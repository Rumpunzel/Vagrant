class_name DiceLog
extends PanelContainer

signal entry_added(entry: Control)

@export_group("Configuration")
@export var _scroll_container: ScrollContainer
@export var _log_entries: Container
@export var _dice_log_die_entry: PackedScene

func _ready() -> void:
	DiceRoller.die_rolled.connect(_on_die_rolled)

func _exit_tree() -> void:
	DiceRoller.die_rolled.disconnect(_on_die_rolled)

func _on_die_rolled(die: Die) -> void:
	var dice_log_entry: DiceLogDieEntry = _dice_log_die_entry.instantiate()
	_log_entries.add_child(dice_log_entry)
	dice_log_entry.initialize_die_result(die)

func _on_entry_entered_tree(node: Node) -> void:
	if not node is Control: return
	await get_tree().process_frame
	_scroll_container.ensure_control_visible(node as Control)
	entry_added.emit(node)
