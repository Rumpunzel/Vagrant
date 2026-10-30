class_name StorySaveDecision
extends StoryDiceDecision

func get_adventure_decision() -> AdventureSaveDecision: return _adventure_decision
func get_dice_request() -> SaveRequest: return dice_request
func get_dice_result() -> SaveResult: return dice_result

func get_consequences() -> Array[StoryConsequence]:
	var decision: AdventureSaveDecision = get_adventure_decision()
	var story_consequences: Array[StoryConsequence] = []
	story_consequences.assign(decision.get_consequences_of(decision.get_outcome(get_dice_result().is_success())).map(StoryConsequence.from_adventure_consequence))
	return story_consequences

func get_transition_reference() -> AdventurePageReference:
	return get_adventure_decision().get_reference(get_adventure_decision().get_outcome(get_dice_result().is_success()))
