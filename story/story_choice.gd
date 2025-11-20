@abstract
class_name StoryChoice
extends RefCounted

signal chosen
@warning_ignore("unused_signal")
signal icon_changed
@warning_ignore("unused_signal")
signal dice_requested(dice_request: DiceRequest)

var _adventure_decision: AdventureDecision :
	set(new_adventure_decision):
		_adventure_decision = new_adventure_decision
		var transition: AdventurePageReference = _adventure_decision.transition
		if transition: _adventure_decision.transition.prepare()
var _protagonist_getter: Callable

func _init(adventure_decision: AdventureDecision, protagonist_getter: Callable) -> void:
	_adventure_decision = adventure_decision
	_protagonist_getter = protagonist_getter

static func from_story_decision(adventure_decision: AdventureDecision, protagonist_getter: Callable) -> StoryChoice:
	if adventure_decision is AdventureSaveDecision: return StorySaveDecision.new(adventure_decision, protagonist_getter)
	elif adventure_decision is AdventureFightDecision: return StoryFightDecision.new(adventure_decision, protagonist_getter)
	return StoryDecision.new(adventure_decision, protagonist_getter)

@abstract func chose() -> void
@abstract func discard() -> void

@abstract func resolve_consequences() -> void

@abstract func is_chosen() -> bool
@abstract func is_dice_choice() -> bool

@abstract func get_adventure_decision() -> AdventureDecision
@abstract func get_transition() -> AdventurePage

func get_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	story_consequences.assign(get_adventure_decision().consequences.map(StoryConsequence.new))
	return story_consequences

func get_description() -> String: return get_adventure_decision().description
func get_icon() -> Texture2D: return get_adventure_decision().get_icon()
func get_icon_color() -> Color: return get_adventure_decision().get_color()

func _chose() -> void: chosen.emit()
