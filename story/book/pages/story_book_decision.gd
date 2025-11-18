class_name StoryBookDecision
extends StoryBookChoice

var _story_decision: StoryDecision
var _chosen: bool = false

func _init(story_decision: StoryDecision) -> void:
	_story_decision = story_decision

func chose() -> void:
	assert(not _chosen)
	_chosen = true
	_chose()

func discard() -> void: assert(not is_chosen(), "Chosen StoryBookDecisions cannot be discarded!")

func is_chosen() -> bool: return _chosen
func is_dice_choice() -> bool: return false

func get_story_decision() -> StoryDecision: return _story_decision
func get_transition() -> StoryPage: return _story_decision.transition.get_story_page()
