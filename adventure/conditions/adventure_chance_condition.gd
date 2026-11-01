@tool
class_name AdventureChanceCondition
extends AdventureCondition

## True by chance, [member times] in [member out_of]: rolled once each time the player arrives at a location ([method Story.roll_chance]), so an
## event (an ambush) may or may not happen there; the player sees no roll

@export_range(1, 100) var times: int = 1
@export_range(1, 100) var out_of: int = 2

func is_true(story: Story, _page: AdventurePage) -> bool: return story.roll_chance(self)

func describe() -> String: return "%d in %d chance" % [times, out_of]
