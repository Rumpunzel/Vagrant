@tool
class_name AdventureGainConsequence
extends AdventureConsequence

## The protagonist gains [member count] of [member item] (gear as fresh pieces); the next page tells it

@export var item: ItemProfile
@export_range(1, 99) var count: int = 1

func resolve(story: Story, _margin: int) -> void:
	if item != null: story.give(item, count)

func describe() -> String: return "Gain %s" % ItemProfile.describe_amount(item, count)
