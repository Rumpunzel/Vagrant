class_name StoryDecision
extends StoryChoice

var _chosen: bool = false

func chose() -> void:
	assert(not _chosen)
	_chosen = true
	_chose()

func discard() -> void: assert(not is_chosen(), "Chosen StoryDecisions cannot be discarded!")

func is_chosen() -> bool: return _chosen
func is_dice_choice() -> bool: return false

func resolve_consequences() -> void:
	for consequence: StoryConsequence in get_consequences(): consequence.resolve(null, 0)

func get_adventure_decision() -> AdventureDecision: return _adventure_decision

func get_transition() -> AdventurePage:
	var transition: AdventurePageReference = get_adventure_decision().transition
	return transition.get_adventure_page() if transition else null
