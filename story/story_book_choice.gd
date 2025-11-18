@abstract
class_name StoryChoice
extends RefCounted

signal chosen

static func from_story_decision(adventure_decision: AdventureDecision, protagonist: Character) -> StoryChoice:
	if adventure_decision is AdventureSaveDecision: return StorySaveDecision.new(adventure_decision as AdventureSaveDecision, protagonist)
	elif adventure_decision is AdventureFightDecision: return StoryFightDecision.new(adventure_decision as AdventureFightDecision, protagonist)
	return StoryDecision.new(adventure_decision)

@abstract func chose() -> void
@abstract func discard() -> void

@abstract func is_chosen() -> bool
@abstract func is_dice_choice() -> bool

@abstract func get_adventure_decision() -> AdventureDecision
@abstract func get_transition() -> AdventurePage

func get_description() -> String: return get_adventure_decision().description
func get_icon() -> Texture2D: return get_adventure_decision().get_icon()
func get_icon_color() -> Color: return get_adventure_decision().get_color()

func _chose() -> void:
	chosen.emit()
