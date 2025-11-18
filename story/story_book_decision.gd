class_name StoryDecision
extends StoryChoice

var _adventure_decision: AdventureDecision
var _chosen: bool = false

func _init(adventure_decision: AdventureDecision) -> void:
	_adventure_decision = adventure_decision

func chose() -> void:
	assert(not _chosen)
	_chosen = true
	_chose()

func discard() -> void: assert(not is_chosen(), "Chosen StoryDecisions cannot be discarded!")

func is_chosen() -> bool: return _chosen
func is_dice_choice() -> bool: return false

func get_adventure_decision() -> AdventureDecision: return _adventure_decision
func get_transition() -> AdventurePage:
	var transition: AdventureTransition = _adventure_decision.transition
	return transition.get_adventure_page() if transition else null
