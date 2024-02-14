extends VBoxContainer

func update_attributes(character: Character) -> void:
	if character == null:
		%MuscleScore.value = 0
		%BloodScore.value = 0
		%GutsScore.value = 0
		%BrainScore.value = 0
		%NerveScore.value = 0
		%HeartScore.value = 0
	else:
		%MuscleScore.value = character.muscle
		%BloodScore.value = character.blood
		%GutsScore.value = character.guts
		%BrainScore.value = character.brain
		%NerveScore.value = character.nerve
		%HeartScore.value = character.heart
