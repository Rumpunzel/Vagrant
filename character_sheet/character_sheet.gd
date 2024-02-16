class_name CharacterSheet
extends PanelContainer

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.attribute_scores_changed.disconnect(%Attributes.update_attributes)
			character.hit_dice_changed.disconnect(%HitDice.update_hit_dice)
		character = new_character
		if character == null:
			character = Protagonist
		character.attribute_scores_changed.connect(%Attributes.update_attributes)
		character.hit_dice_changed.connect(%HitDice.update_hit_dice)
		
		name = character.name
		%Portrait.texture = character.portrait
		%Attributes.update_attributes(character)
		%HitDice.update_hit_dice(character)
		%Name.text = character.name
