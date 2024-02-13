extends MarginContainer

@export var character: Character :
	set(new_character):
		if character != null:
			character.attributes.attributes_changed.disconnect(_update_attributes)
			character.hit_dice.dice_pool_changed.disconnect(_update_hit_dice)
		character = new_character
		character.attributes.attributes_changed.connect(_update_attributes)
		character.hit_dice.dice_pool_changed.connect(_update_hit_dice)
		if character != null:
			_update_attributes(character.attributes)
			_update_hit_dice(character.hit_dice)
		else:
			_update_attributes(null)
			_update_hit_dice(null)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_attributes(new_attributes: CharacterAttributes) -> void:
	if new_attributes == null:
		%MuscleScore.value = 0
		%BloodScore.value = 0
		%GutsScore.value = 0
		%BrainScore.value = 0
		%NerveScore.value = 0
		%HeartScore.value = 0
	else:
		%MuscleScore.value = new_attributes.muscle
		%BloodScore.value = new_attributes.blood
		%GutsScore.value = new_attributes.guts
		%BrainScore.value = new_attributes.brain
		%NerveScore.value = new_attributes.nerve
		%HeartScore.value = new_attributes.heart

func _update_hit_dice(new_hit_dice: DicePool) -> void:
	if new_hit_dice == null:
		%d4.update_counter(0)
		%d6.update_counter(0)
		%d8.update_counter(0)
		%d10.update_counter(0)
		%d12.update_counter(0)
	else:
		%d4.update_counter(new_hit_dice.get_dice_count(DicePool.Dice.d4))
		%d6.update_counter(new_hit_dice.get_dice_count(DicePool.Dice.d6))
		%d8.update_counter(new_hit_dice.get_dice_count(DicePool.Dice.d8))
		%d10.update_counter(new_hit_dice.get_dice_count(DicePool.Dice.d10))
		%d12.update_counter(new_hit_dice.get_dice_count(DicePool.Dice.d12))
