extends VBoxContainer

@export var _character_sheet: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_character_list() -> void:
	for character_sheet: CharacterSheet in get_children():
		remove_child(character_sheet)
		character_sheet.queue_free()
	for character: Character in get_tree().get_nodes_in_group(Character.GROUP):
		var character_sheet: CharacterSheet = _character_sheet.instantiate()
		character_sheet.character = character
		add_child(character_sheet)
