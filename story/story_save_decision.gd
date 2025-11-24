class_name StorySaveDecision
extends StoryDiceDecision

func get_adventure_decision() -> AdventureSaveDecision: return _adventure_decision
func get_dice_request() -> SaveRequest: return dice_request
func get_dice_result() -> SaveResult: return dice_result

func get_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	if get_dice_result().is_success(): story_consequences.assign(get_adventure_decision().consequences.map(StoryConsequence.from_adventure_consequence))
	else: story_consequences.assign(get_adventure_decision().failure_consequences.map(StoryConsequence.from_adventure_consequence))
	return story_consequences

func get_transition() -> AdventurePage:
	if get_dice_result().is_success(): return get_adventure_decision().transition.get_adventure_page()
	else: return get_adventure_decision().failure_transition.get_adventure_page()
