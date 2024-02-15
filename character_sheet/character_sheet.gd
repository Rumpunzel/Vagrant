extends PanelContainer

@export var character: Character :
	set(new_character):
		if character != null:
			character.attributes_changed.disconnect(%Attributes.update_attributes)
			character.hit_dice_changed.disconnect(%HitDice.update_hit_dice)
		character = new_character
		character.attributes_changed.connect(%Attributes.update_attributes)
		character.hit_dice_changed.connect(%HitDice.update_hit_dice)
		if is_inside_tree(): _update_sheet()

func _ready() -> void:
	_update_sheet()

func _update_sheet() -> void:
	if character != null:
		%Portrait.texture = character.portrait
		%Attributes.update_attributes(character._attributes)
		%HitDice.update_hit_dice(character.hit_dice)
		%Name.text = character.name
	else:
		%Portrait.texture = null
		%Attributes.update_attributes(null)
		%HitDice.update_hit_dice(null)
		%Name.text = ""
