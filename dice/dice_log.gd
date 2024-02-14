extends VBoxContainer

@export var _dice_log_entry: PackedScene
@export var _hit_dice_selection: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DiceRoller.save_rolled.connect(_on_save_rolled)

func _exit_tree() -> void:
	DiceRoller.save_rolled.disconnect(_on_save_rolled)

func request_save(character: Character, attribute: Character.Attributes, difficulty: int, description: String) -> void:
	var hit_dice_selection: HitDiceSelection = _hit_dice_selection.instantiate()
	hit_dice_selection.initialize_dice_selection(character, attribute, difficulty, description)
	add_child(hit_dice_selection)
	hit_dice_selection.grab_focus()

func _on_die_rolled(die_result: DiceRoller.DieResult) -> void:
	var dice_log_entry: DiceLogEntry = _dice_log_entry.instantiate()
	dice_log_entry.initialize_die_result(die_result)
	add_child(dice_log_entry)
	dice_log_entry.grab_focus()

func _on_save_rolled(save_result: DiceRoller.SaveResult) -> void:
	var dice_log_entry: DiceLogEntry = _dice_log_entry.instantiate()
	dice_log_entry.initialize_save_result(save_result)
	add_child(dice_log_entry)
	dice_log_entry.grab_focus()
