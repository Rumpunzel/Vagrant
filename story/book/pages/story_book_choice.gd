@abstract
class_name StoryBookChoice
extends RefCounted

signal chosen

static func from_story_decision(story_decision: StoryDecision, protagonist: Character) -> StoryBookChoice:
	if story_decision is StorySaveDecision: return StoryBookSaveDecision.new(story_decision as StorySaveDecision, protagonist)
	elif story_decision is StoryFightDecision: return StoryBookFightDecision.new(story_decision as StoryFightDecision, protagonist)
	return StoryBookDecision.new(story_decision)

@abstract func chose() -> void
@abstract func discard() -> void

@abstract func is_chosen() -> bool
@abstract func is_dice_choice() -> bool

@abstract func get_story_decision() -> StoryDecision
@abstract func get_transition() -> StoryPage

func get_description() -> String: return get_story_decision().description
func get_icon() -> Texture2D: return get_story_decision().get_icon()
func get_icon_color() -> Color: return get_story_decision().get_color()

func _chose() -> void:
	chosen.emit()
