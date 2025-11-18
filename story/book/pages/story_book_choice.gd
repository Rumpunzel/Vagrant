@abstract
class_name StoryBookChoice
extends RefCounted

signal chosen

static func from_story_decision(adventure_decision: AdventureDecision, protagonist: Character) -> StoryBookChoice:
	if adventure_decision is AdventureSaveDecision: return StoryBookSaveDecision.new(adventure_decision as AdventureSaveDecision, protagonist)
	elif adventure_decision is AdventureFightDecision: return StoryBookFightDecision.new(adventure_decision as AdventureFightDecision, protagonist)
	return StoryBookDecision.new(adventure_decision)

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
