@tool
class_name AdventureCarriesCondition
extends AdventureCondition

## True while the protagonist carries at least [member at_least] of [member item] (gear: pieces not ruined)

@export var item: ItemProfile
@export_range(1, 99) var at_least: int = 1

func is_true(story: Story, _page: AdventurePage) -> bool:
	return item != null and story.get_protagonist().count_of(item) >= at_least

func describe() -> String: return "Carries %s" % ItemProfile.describe_amount(item, at_least, "%d or more %s")
