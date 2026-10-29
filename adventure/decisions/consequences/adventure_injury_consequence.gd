@tool
class_name AdventureInjuryConsequence
extends AdventureConsequence

## The margin is the damage
func resolve(story: Story, margin: int) -> void:
	if margin <= 0: return
	story.get_protagonist().suffer_injury(Injury.new(margin))

func describe() -> String: return "Injury (margin as damage)"
