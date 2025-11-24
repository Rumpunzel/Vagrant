@abstract
class_name StoryChoice
extends RefCounted

signal chosen
signal discarded
@warning_ignore("unused_signal")
signal icon_changed
@warning_ignore("unused_signal")
signal dice_requested(dice_request: DiceRequest)
@warning_ignore("unused_signal")
signal roll_requested(dice_request: DiceRequest)

var _adventure_decision: AdventureDecision :
	set(new_adventure_decision):
		_adventure_decision = new_adventure_decision
		var transition: AdventurePageReference = _adventure_decision.transition
		if transition: _adventure_decision.transition.prepare()

func _init(adventure_decision: AdventureDecision, protagonist: Character) -> void:
	_adventure_decision = adventure_decision
	_setup(protagonist)

static func from_adventure_decision(adventure_decision: AdventureDecision, protagonist: Character) -> StoryChoice:
	if adventure_decision is AdventureSaveDecision: return StorySaveDecision.new(adventure_decision, protagonist)
	elif adventure_decision is AdventureFightDecision: return StoryFightDecision.new(adventure_decision, protagonist)
	return StoryDecision.new(adventure_decision, protagonist)

@abstract func chose() -> void
func discard() -> void: assert(not is_chosen()); discarded.emit()
@abstract func roll() -> void

@abstract func is_chosen() -> bool
@abstract func is_dice_choice() -> bool

@abstract func get_adventure_decision() -> AdventureDecision
@abstract func get_dice_request() -> DiceRequest
@abstract func get_dice_result() -> DiceResult
@abstract func get_transition() -> AdventurePage
@abstract func get_consequences() -> Array[StoryConsequence]

func get_description() -> String: return get_adventure_decision().description
func get_icon() -> Texture2D: return get_adventure_decision().get_icon()
func get_icon_color() -> Color: return get_adventure_decision().get_color()

@abstract func _setup(protagonist: Character) -> void
func _chose() -> void: chosen.emit()
@abstract func _on_dice_rolled(rolled_dice_result: DiceResult) -> void
