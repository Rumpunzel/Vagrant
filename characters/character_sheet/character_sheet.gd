class_name CharacterSheet
extends PanelContainer

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.attribute_scores_changed.disconnect(_attributes.update_attributes)
			character.hit_dice_changed.disconnect(_hit_dice.update_hit_dice)
		character = new_character
		character.attribute_scores_changed.connect(_attributes.update_attributes)
		character.hit_dice_changed.connect(_hit_dice.update_hit_dice)
		name = character.name
		_portrait.texture = character.portrait
		_name.text = character.name
		_attributes.update_attributes(character)
		_hit_dice.update_hit_dice(character.hit_dice)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _name: Label
@export var _attributes: CharacterAttributesPanel
@export var _hit_dice: HitDiceSelectionButtons
