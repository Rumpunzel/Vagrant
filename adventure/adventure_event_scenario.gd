@tool
class_name AdventureEventScenario
extends AdventureEvent

## Groups events and shows at most one of them: the first of its [member AdventureEventHost.events] whose prerequisites are met (list order is priority).
## Its own conditions gate the whole group; the chosen event acts on the host as if it were listed there (also its Hide flags).
## Its title only names it in the editor; the other page fields are unused.

const UNUSED: Array[StringName] = [&"description", &"background", &"ambience", &"decisions", &"exclusivity"]

func resolve_event(story: Story) -> AdventureEvent:
	for event: AdventureEvent in events:
		if not event.are_all_prerequisites_fullfilled(story): continue
		var shown: AdventureEvent = event.resolve_event(story)
		if shown != null: return shown
	return null

func _validate_property(property: Dictionary) -> void:
	if UNUSED.has(property.name): property.usage = PROPERTY_USAGE_NO_EDITOR
