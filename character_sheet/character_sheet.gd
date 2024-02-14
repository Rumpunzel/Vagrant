extends PanelContainer

@export var character: Character :
	set(new_character):
		if character != null:
			character.attributes_changed.disconnect(%Attributes.update_attributes)
			character.hit_dice.dice_pool_changed.disconnect(%HitDice.update_hit_dice)
		character = new_character
		character.attributes_changed.connect(%Attributes.update_attributes.bind(character))
		character.hit_dice.dice_pool_changed.connect(%HitDice.update_hit_dice)
		%Attributes.update_attributes(character)
		if character != null:
			%Portrait.texture = character.portrait
			%HitDice.update_hit_dice(character.hit_dice)
			%Name.text = character.name
		else:
			%Portrait.texture = null
			%HitDice.update_hit_dice(null)
			%Name.text = ""
