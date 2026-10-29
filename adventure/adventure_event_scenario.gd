@tool
class_name AdventureEventScenario
extends AdventurePage

## Groups events and shows at most one of them: the first of its [member AdventurePage.events] whose prerequisites are met (list order is priority).
## Its own conditions gate the whole group; the chosen event acts on the host as if it were listed there (also its Hide flags).
## Its title only names it in the editor; the other page fields are unused.

const UNUSED: Array[StringName] = [&"description", &"area", &"background", &"ambience", &"decisions", &"exclusivity"]

func resolve_event(story: Story) -> AdventurePage:
	for event: AdventurePage in events:
		if not event.are_all_prerequisites_fullfilled(story): continue
		var shown: AdventurePage = event.resolve_event(story)
		if shown != null: return shown
	return null

func _validate_property(property: Dictionary) -> void:
	if UNUSED.has(property.name): property.usage = PROPERTY_USAGE_NO_EDITOR
