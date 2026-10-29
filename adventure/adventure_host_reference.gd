@tool
class_name AdventureHostReference
extends AdventurePageReference

## "↺ Host": the page the event was shown on ([method Story.get_host]), so an event works on any page. Alone it knows no page.

func prepare() -> void: pass
func get_adventure_page() -> AdventurePage: return null
func resolve(story: Story) -> AdventurePage: return story.get_host()
