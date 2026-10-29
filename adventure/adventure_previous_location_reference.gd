@tool
class_name AdventurePreviousLocationReference
extends AdventurePageReference

## "↶ Previous location": back to where the player was before the event's host (fleeing an ambush), however many pages deep the event goes.
## Story goes back to it ([method Story.get_host]); alone it knows no page.

func prepare() -> void: pass
func get_adventure_page() -> AdventurePage: return null
