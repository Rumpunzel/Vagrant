class_name StoryDecision
extends StoryChoice

var _chosen: bool = false

func chose() -> void:
	assert(not _chosen)
	_chosen = true
	_chose()

func roll() -> void: assert(false, "StoryDecision cannot roll")
func is_chosen() -> bool: return _chosen
func is_dice_choice() -> bool: return false

func get_adventure_decision() -> AdventureDecision: return _adventure_decision
func get_dice_request() -> DiceRequest: assert(false, "StoryDecision has no DiceRequest"); return null
func get_dice_result() -> DiceResult: assert(false, "StoryDecision has no DiceResult"); return null

func get_transition_reference() -> AdventurePageReference: return get_adventure_decision().transition

func get_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	story_consequences.assign(get_adventure_decision().consequences.map(StoryConsequence.from_adventure_consequence))
	return story_consequences

func _setup(_protagonist: Character) -> void: pass

func _on_dice_rolled(_rolled_dice_result: DiceResult) -> void: assert(false, "StoryDecision cannot be rolled")
