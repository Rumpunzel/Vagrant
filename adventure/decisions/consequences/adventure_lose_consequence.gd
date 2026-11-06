@tool
class_name AdventureLoseConsequence
extends AdventureConsequence

## The protagonist loses up to [member count] of [member item] (of gear, the most worn pieces first); what isn't carried can't be lost

@export var item: ItemProfile
@export_range(1, 99) var count: int = 1

func resolve(story: Story, _margin: int) -> void:
	if item != null: story.take(item, count)

func describe() -> String: return "Lose %s" % ItemProfile.describe_amount(item, count)
