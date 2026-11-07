@tool
class_name AdventureCarriesCondition
extends AdventureCondition

## True while the protagonist carries at least [member at_least] of [member item] (gear: pieces not ruined); [member negated]: while they don't

@export var item: ItemProfile
@export_range(1, 99) var at_least: int = 1
## "Doesn't carry": true while the protagonist carries fewer than [member at_least]
@export var negated: bool = false

func is_true(story: Story, _page: AdventurePage) -> bool:
	if item == null: return false
	return (story.get_protagonist().count_of(item) >= at_least) != negated

func describe() -> String:
	if not negated: return "Carries %s" % ItemProfile.describe_amount(item, at_least, "%d or more %s")
	return "Doesn't carry %s" % ItemProfile.describe_amount(item, 1) if at_least == 1 else "Carries fewer than %d %s" % [at_least, ItemProfile.describe_amount(item, 1)]
