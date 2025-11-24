class_name FightRequest
extends DiceRequest

signal selected_weapon_dice_changed(weapon_dice: Array[WeaponDie])

var selected_weapon_dice: Array[WeaponDie] :
	set(new_sselected_weapon_dice):
		selected_weapon_dice = new_sselected_weapon_dice
		selected_weapon_dice_changed.emit(selected_weapon_dice)

func _init(for_character: Character, source: AdventureFightDecision, new_selected_weapon_dice: Array[WeaponDie] = []) -> void:
	super(for_character, for_character.get_favored_attribute(), source)
	selected_weapon_dice = new_selected_weapon_dice

func get_source() -> AdventureFightDecision: return _source

func get_stance_description(for_attribute: CharacterAttribute) -> String:
	return get_source().stance_descriptions.get(for_attribute, for_attribute.stance_description)

func _create_result() -> FightResult:
	assert(character)
	character.most_recently_chosen_attribute = attribute
	return FightResult.new(self)
